import re
import os

def process_granth_text(full_text):
    """
    1. Splits a continuous string into individual verses based on '॥number॥'.
    2. Formats each verse to have a line break after the second danda.
    """
    
    # --- Step 1: Find all verses ---
    # Regex explanation:
    # .*?       -> Match any character (non-greedy)
    # ॥         -> Match the specific double danda
    # \s* -> Match optional whitespace
    # [\d\u0966-\u096F]+ -> Match digits (0-9) OR Marathi digits (०-९)
    # \s* -> Match optional whitespace
    # ॥         -> Match closing double danda
    verse_pattern = r'(.*?॥\s*[\d\u0966-\u096F]+\s*॥)'
    
    # re.findall returns a list of all strings that match the pattern
    # re.DOTALL ensures it reads across newlines if your input has them
    raw_verses = re.findall(verse_pattern, full_text, re.DOTALL)
    
    formatted_output = []

    # --- Step 2: Format each verse individually ---
    for verse in raw_verses:
        # Clean up the verse: remove existing newlines and extra spaces
        clean_verse = verse.replace('\n', ' ').strip()
        
        # Find the positions of the single dandas (।)
        first_danda = clean_verse.find('।')
        second_danda = clean_verse.find('।', first_danda + 1)
        
        if first_danda != -1 and second_danda != -1:
            # Split after the second danda (+1 to include the danda itself)
            split_point = second_danda + 1
            
            line1 = clean_verse[:split_point].strip()
            line2 = clean_verse[split_point:].strip()
            
            formatted_verse = f"{line1}\n{line2}"
            formatted_output.append(formatted_verse)
        else:
            # If pattern doesn't match (e.g. short lines), keep as is
            formatted_output.append(clean_verse)

    # Join all processed verses with a double newline
    return "\n\n".join(formatted_output)

# ==========================================
# FILE OPERATIONS
# ==========================================

input_filename = "input.txt"
output_filename = "output.txt"

if not os.path.exists(input_filename):
    print(f"❌ Error: '{input_filename}' not found.")
    print("Please create the file and paste your Marathi text inside it.")
else:
    print(f"📖 Reading from '{input_filename}'...")
    
    with open(input_filename, "r", encoding="utf-8") as infile:
        # Read the entire file as one long string
        content = infile.read()

    if not content.strip():
        print("⚠️ Warning: Input file is empty.")
    else:
        # Process the text
        final_result = process_granth_text(content)
        
        # Write to output file
        with open(output_filename, "w", encoding="utf-8") as outfile:
            outfile.write(final_result)
            
        print(f"✅ Success! Formatted text saved to '{output_filename}'")