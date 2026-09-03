import os
import sys
from datetime import datetime
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

def generate_certificate(participant_name, event_title, issue_date, output_path):
    """
    Generate a certificate PDF with the given details
    """
    # Register a font (you might want to use a specific font file)
    # For now we'll use default fonts
    
    # Create a PDF with ReportLab
    c = canvas.Canvas(output_path, pagesize=A4)
    width, height = A4
    
    # Draw the certificate content
    c.setFont("Helvetica", 36)
    c.drawCentredString(width/2.0, height-2*inch, "Сертификат")
    
    c.setFont("Helvetica", 24)
    c.drawCentredString(width/2.0, height-3*inch, "участника")
    
    c.setFont("Helvetica", 30)
    c.setFillColorRGB(0.2, 0.2, 0.8)  # Blue color
    c.drawCentredString(width/2.0, height-4.5*inch, participant_name)
    
    c.setFillColorRGB(0, 0, 0)  # Black color
    c.setFont("Helvetica", 18)
    c.drawCentredString(width/2.0, height-5.5*inch, "успешно participated in")
    
    c.setFont("Helvetica", 20)
    c.drawCentredString(width/2.0, height-6.2*inch, event_title)
    
    c.setFont("Helvetica", 16)
    c.drawCentredString(width/2.0, height-7.2*inch, f"Дата: {issue_date}")
    
    # Add decorative elements
    c.line(inch, height-8*inch, width-inch, height-8*inch)
    
    c.setFont("Helvetica", 14)
    c.drawCentredString(width/2.0, height-8.5*inch, "Организатор: Certy")
    
    # Save the PDF
    c.save()
    print(f"Certificate generated: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python generate_certificate.py <participant_name> <event_title> <issue_date> <output_path>")
        sys.exit(1)
    
    participant_name = sys.argv[1]
    event_title = sys.argv[2]
    issue_date = sys.argv[3]
    output_path = sys.argv[4]
    
    generate_certificate(participant_name, event_title, issue_date, output_path)