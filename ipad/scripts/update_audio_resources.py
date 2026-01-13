#!/usr/bin/env python3
"""
Script to add missing audio files to the Xcode project.
This generates unique UUIDs and adds file references + build file entries.
"""

import os
import re
import hashlib

PROJECT_PATH = "/Users/shashwatshlok/Projects/InvisibleCost-VisionPro/InvisibleCost.xcodeproj/project.pbxproj"
AUDIO_DIR = "/Users/shashwatshlok/Projects/InvisibleCost-VisionPro/ipad/Resources/Audio"

def generate_uuid(seed: str) -> str:
    """Generate a deterministic 24-char hex UUID from a seed string."""
    hash_obj = hashlib.md5(seed.encode())
    return hash_obj.hexdigest()[:24].upper()

def get_existing_files(content: str) -> set:
    """Extract already-registered file names from the project."""
    # Match patterns like: /* narration_agentic.mp3 */
    pattern = r'/\*\s*([a-zA-Z0-9_\-]+\.mp3)\s*\*/'
    matches = re.findall(pattern, content)
    return set(matches)

def get_audio_files() -> list:
    """Get all mp3 files from the Audio directory."""
    files = []
    for f in os.listdir(AUDIO_DIR):
        if f.endswith('.mp3'):
            files.append(f)
    return sorted(files)

def main():
    # Read current project file
    with open(PROJECT_PATH, 'r') as f:
        content = f.read()

    existing_files = get_existing_files(content)
    audio_files = get_audio_files()

    # Find missing files
    missing_files = [f for f in audio_files if f not in existing_files]

    if not missing_files:
        print("All audio files are already in the project!")
        return

    print(f"Found {len(missing_files)} missing audio files:")
    for f in missing_files:
        print(f"  - {f}")

    # Generate file references and build files
    file_refs = []
    build_files = []
    group_children = []

    for filename in missing_files:
        # Generate UUIDs
        file_ref_uuid = generate_uuid(f"fileref_{filename}_v2")
        build_file_uuid = generate_uuid(f"buildfile_{filename}_v2")

        # PBXFileReference entry
        file_ref = f'\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = audio.mp3; path = {filename}; sourceTree = "<group>"; }};'
        file_refs.append(file_ref)

        # PBXBuildFile entry
        build_file = f'\t\t{build_file_uuid} /* {filename} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};'
        build_files.append(build_file)

        # Group children entry
        group_children.append(f'\t\t\t\t{file_ref_uuid} /* {filename} */,')

        print(f"Generated refs for {filename}: fileRef={file_ref_uuid}, buildFile={build_file_uuid}")

    # Insert file references before /* End PBXFileReference section */
    file_refs_str = '\n'.join(file_refs)
    content = content.replace(
        '/* End PBXFileReference section */',
        f'{file_refs_str}\n/* End PBXFileReference section */'
    )

    # Insert build files before /* End PBXBuildFile section */
    build_files_str = '\n'.join(build_files)
    content = content.replace(
        '/* End PBXBuildFile section */',
        f'{build_files_str}\n/* End PBXBuildFile section */'
    )

    # Add to Audio group children (find the Audio group and add entries)
    # The Audio group has path = Audio and contains existing audio files
    # We need to find the children array of the Audio group

    # Find the Audio group section
    audio_group_pattern = r'(469C33ED2F07DD48002E908D /\* Audio \*/ = \{\s*isa = PBXGroup;\s*children = \()'

    group_children_str = '\n'.join(group_children)
    content = re.sub(
        audio_group_pattern,
        r'\1\n' + group_children_str,
        content
    )

    # Add build file references to the iPad Resources build phase
    # Find: 46B7609C2F024AD600F1A587 /* Resources */
    # and add our build file UUIDs to its files array

    # Generate the build phase file entries
    build_phase_entries = []
    for filename in missing_files:
        build_file_uuid = generate_uuid(f"buildfile_{filename}_v2")
        build_phase_entries.append(f'\t\t\t\t{build_file_uuid} /* {filename} in Resources */,')

    build_phase_str = '\n'.join(build_phase_entries)

    # Find the iPad Resources build phase and add entries after the first file
    # Pattern: find the Resources build phase for iPad target
    ipad_resources_pattern = r'(46B7609C2F024AD600F1A587 /\* Resources \*/ = \{\s*isa = PBXResourcesBuildPhase;\s*buildActionMask = \d+;\s*files = \()'

    content = re.sub(
        ipad_resources_pattern,
        r'\1\n' + build_phase_str,
        content
    )

    # Write the updated project file
    with open(PROJECT_PATH, 'w') as f:
        f.write(content)

    print(f"\nSuccessfully added {len(missing_files)} audio files to the project!")
    print("Please rebuild the project in Xcode.")

if __name__ == "__main__":
    main()
