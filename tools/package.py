"""Create Mario VR installation and matching source archives."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip().replace(" ", "-")
TEXT_ROOT = [
    "README.md", "INSTALL.md", "KNOWN-ISSUES.md", "RELEASE_NOTES.md",
    "CREDITS.md", "THIRD-PARTY.txt", "LICENSE", "VERSION", "BUILD.md",
]
START_FILES = ["Start-VR.cmd", "Start-VR.ps1"]
# The installation ZIP holds exactly one folder with this name. Copy it into
# your Cemu folder, open it, double-click Start-VR.cmd - that is the install.
INSTALL_FOLDER = "Mario3DWorld-VR"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def source_files() -> dict[str, bytes]:
    result: dict[str, bytes] = {}
    for name in TEXT_ROOT + START_FILES + ["CMakeLists.txt", ".gitignore", ".gitattributes"]:
        result[name] = (ROOT / name).read_bytes()
    for directory, suffixes in [
        ("core", {".h", ".cpp", ".def"}),
        ("graphicPacks", {".asm", ".txt"}),
        ("layer", {".json"}),
        ("licenses", {".txt"}),
        ("tools", {".py"}),
    ]:
        for path in sorted((ROOT / directory).rglob("*")):
            if path.is_file() and path.suffix in suffixes:
                result[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    return result


def install_files(dll: Path) -> dict[str, bytes]:
    result = {name: (ROOT / name).read_bytes() for name in TEXT_ROOT}
    # The start file and its script: plain text, no executable, no installer.
    for name in START_FILES:
        result[name] = (ROOT / name).read_bytes()
    result["layer/cemuvr_layer.dll"] = dll.read_bytes()
    result["layer/VK_LAYER_CEMUVR_core.json"] = (ROOT / "layer/VK_LAYER_CEMUVR_core.json").read_bytes()
    for path in sorted((ROOT / "graphicPacks").rglob("*")):
        if path.is_file() and path.suffix in {".asm", ".txt"}:
            result[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    for path in sorted((ROOT / "licenses").glob("*.txt")):
        result[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    result["SHA256.json"] = json.dumps(
        {name: digest(data) for name, data in sorted(result.items())}, indent=2
    ).encode("utf-8") + b"\n"
    return result


def audit(name: str, files: dict[str, bytes]) -> None:
    forbidden_names = re.compile(r"(?i)(\.exe$|\.rpx$|\.wud$|\.wux$|\.tik$|\.tmd$|gamedata\.bin|save|shadercache|\.pdb$)")
    # Assemble markers in pieces so the checker can audit its own source too.
    forbidden_text = re.compile(rb"(?i)(" + b"|".join([
        rb"[A-Z]:\\(?:Users|AI|EMULATION)\\",
        b"/" + b"Users/",
        # A real path segment, not the %APPDATA% variable the instructions name.
        rb"\App" + rb"Data\\",
        b"sv" + b"vee",
        b"gh" + rb"p_[A-Za-z0-9]+",
        b"github" + rb"_pat_[A-Za-z0-9]+",
        b"Bearer" + rb" [A-Za-z0-9]+",
    ]) + rb")")
    for path, data in files.items():
        if forbidden_names.search(path):
            raise ValueError(f"Forbidden filename in {name}: {path}")
        if path.endswith(".dll"):
            # The binary is scanned too; it must not embed a private build path.
            if forbidden_text.search(data):
                raise ValueError(f"Private path or credential in {name}: {path}")
        elif forbidden_text.search(data):
            raise ValueError(f"Private path or credential in {name}: {path}")


def write_zip(path: Path, prefix: str, files: dict[str, bytes]) -> None:
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            archive.writestr(prefix + "/" + name, data)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dll", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=ROOT / "Releases")
    args = parser.parse_args()
    if not args.dll.is_file():
        parser.error(f"DLL does not exist: {args.dll}")
    args.out.mkdir(parents=True, exist_ok=True)

    source = source_files()
    install = install_files(args.dll)
    audit("source", source)
    audit("installation", install)
    base = f"SuperMario3DWorld-VR-{VERSION}"
    installation_zip = args.out / f"{base}-install.zip"
    source_zip = args.out / f"{base}-source.zip"
    write_zip(installation_zip, INSTALL_FOLDER, install)
    write_zip(source_zip, base + "-source", source)
    sums = "".join(
        f"{digest(path.read_bytes())}  {path.name}\n"
        for path in (installation_zip, source_zip)
    )
    (args.out / "SHA256SUMS.txt").write_text(sums, encoding="utf-8")
    print(installation_zip)
    print(source_zip)
    print(args.out / "SHA256SUMS.txt")


if __name__ == "__main__":
    main()
