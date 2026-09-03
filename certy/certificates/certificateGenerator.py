import os
import sys
import json
from datetime import datetime
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, letter
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pathlib import Path


def load_template(template_path):
    """Load an HTML template and return its content"""
    with open(template_path, 'r', encoding='utf-8') as file:
        return file.read()


def generate_certificate_pdf(participant_name, event_title, issue_date, template_path, output_path):
    """Generate a certificate PDF using an HTML template"""
    from pyhtml2pdf import convert
    
    # Load the template
    template_html = load_template(template_path)
    
    # Replace placeholders with actual data
    certificate_html = template_html.replace('[PARTICIPANT NAME]', participant_name)
    certificate_html = certificate_html.replace('[EVENT TITLE]', event_title)
    certificate_html = certificate_html.replace('[DATE]', issue_date.strftime('%B %d, %Y'))
    certificate_html = certificate_html.replace('[CERTIFICATE_ID]', f"CERT-{datetime.now().strftime('%Y%m%d%H%M%S')}")
    
    # Create temporary HTML file
    temp_html_path = output_path.replace('.pdf', '.html')
    with open(temp_html_path, 'w', encoding='utf-8') as f:
        f.write(certificate_html)
    
    # Convert HTML to PDF
    convert(temp_html_path, output_path)
    
    # Remove temporary HTML file
    os.remove(temp_html_path)
    
    print(f"Certificate generated: {output_path}")


def generate_certificates_batch(participants_list, event_title, template_path, output_dir):
    """Generate multiple certificates for a list of participants"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    results = []
    
    for i, participant in enumerate(participants_list):
        # Format participant name (could be a string or dict)
        if isinstance(participant, dict):
            name = participant.get('name', participant.get('full_name', ''))
            email = participant.get('email', '')
        else:
            name = participant
            email = ''
        
        # Generate unique filename
        safe_name = "".join(c for c in name if c.isalnum() or c in (' ', '-', '_')).rstrip()
        output_path = os.path.join(output_dir, f"certificate_{i+1:03d}_{safe_name.replace(' ', '_')}.pdf")
        
        try:
            generate_certificate_pdf(
                participant_name=name,
                event_title=event_title,
                issue_date=datetime.now(),
                template_path=template_path,
                output_path=output_path
            )
            results.append({
                'name': name,
                'email': email,
                'status': 'success',
                'file_path': output_path
            })
        except Exception as e:
            print(f"Error generating certificate for {name}: {str(e)}")
            results.append({
                'name': name,
                'email': email,
                'status': 'error',
                'error': str(e)
            })
    
    return results


def main():
    if len(sys.argv) < 4:
        print("Usage: python certificate_generator.py <template_path> <output_dir> <event_title> [participants_file]")
        print("If participants_file is not provided, a single certificate will be generated")
        sys.exit(1)
    
    template_path = sys.argv[1]
    output_dir = sys.argv[2]
    event_title = sys.argv[3]
    
    if len(sys.argv) > 4:
        # Batch generation from a file
        participants_file = sys.argv[4]
        
        # Read participants from file (JSON or text)
        if participants_file.endswith('.json'):
            with open(participants_file, 'r', encoding='utf-8') as f:
                participants = json.load(f)
        else:
            # Assume text file with one name per line
            with open(participants_file, 'r', encoding='utf-8') as f:
                participants = [line.strip() for line in f if line.strip()]
        
        results = generate_certificates_batch(
            participants_list=participants,
            event_title=event_title,
            template_path=template_path,
            output_dir=output_dir
        )
    else:
        # Single certificate generation
        participant_name = input("Enter participant name: ")
        output_path = os.path.join(output_dir, f"certificate_{participant_name.replace(' ', '_')}.pdf")
        
        generate_certificate_pdf(
            participant_name=participant_name,
            event_title=event_title,
            issue_date=datetime.now(),
            template_path=template_path,
            output_path=output_path
        )
        results = [{'name': participant_name, 'status': 'success', 'file_path': output_path}]
    
    # Print results
    print("\nGeneration Results:")
    for result in results:
        if result['status'] == 'success':
            print(f"✓ {result['name']}: {result['file_path']}")
        else:
            print(f"✗ {result['name']}: {result['error']}")


if __name__ == "__main__":
    main()