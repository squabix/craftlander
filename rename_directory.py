import os
import re

def match_case(target, replacement):
    if target.isupper():
        return replacement.upper()
    elif target.istitle():
        return replacement.capitalize()
    else:
        return replacement.lower()

def replace_with_case(text, search_str, replace_str):
    def re_replace(match):
        matched_text = match.group(0)
        return match_case(matched_text, replace_str)
    
    # Case-insensitive regex match
    pattern = re.compile(re.escape(search_str), re.IGNORECASE)
    return pattern.sub(re_replace, text)

def process_directory(root_dir, search_str, replace_str):
    for dirpath, dirnames, filenames in os.walk(root_dir, topdown=False):
        
        # Update content inside text files
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                updated_content = replace_with_case(content, search_str, replace_str)
                
                if updated_content != content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(updated_content)
                    print(f"Updated content in {file_path}")
            except (UnicodeDecodeError, PermissionError):
                pass # Skip binary files and unreadable files

        # Rename files
        for filename in filenames:
            new_filename = replace_with_case(filename, search_str, replace_str)
            if new_filename != filename:
                old_path = os.path.join(dirpath, filename)
                new_path = os.path.join(dirpath, new_filename)
                os.rename(old_path, new_path)
                print(f"Renamed file {filename} to {new_filename}")

        # Rename directories
        # Bottom-up execution prevents pathing errors
        for dirname in dirnames:
            new_dirname = replace_with_case(dirname, search_str, replace_str)
            if new_dirname != dirname:
                old_path = os.path.join(dirpath, dirname)
                new_path = os.path.join(dirpath, new_dirname)
                os.rename(old_path, new_path)
                print(f"Renamed folder {dirname} to {new_dirname}")

if __name__ == "__main__":
    target_directory = input("Target directory: ")
    from_str = input("Replace from: ")
    to_str = input("Replace to: ")

    process_directory(target_directory, from_str, to_str)