import re
import PyPDF2

def recover_text_from_pdf(pdf_path, output_filename):
    print(f"📖 Opening {pdf_path}...")
    
    full_text = ""
    
    try:
        with open(pdf_path, 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            total_pages = len(reader.pages)
            print(f"📄 Found {total_pages} pages. Extracting text...")
            
            for i, page in enumerate(reader.pages):
                text = page.extract_text()
                if text:
                    # Optional: Clean up header/footers if they appear on every page
                    # text = text.replace("Jai Gajanan", "") 
                    full_text += text + "\n\n"
                    
                # Print progress every 20 pages
                if (i + 1) % 20 == 0:
                    print(f"   Processed {i + 1}/{total_pages} pages...")

    except FileNotFoundError:
        print(f"❌ Error: Could not find '{pdf_path}'. Make sure it is in this folder.")
        return

    # Save to a text file
    with open(output_filename, "w", encoding="utf-8") as f:
        f.write(full_text)
        
    print(f"\n✅ Success! Your text is recovered in: '{output_filename}'")

# --- EXECUTE ---
recover_text_from_pdf('Shri_Gajanan_Vijay_Grantha_English_Pothi.pdf', 'recovered_granth.txt')