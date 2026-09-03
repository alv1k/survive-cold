# Certificate Templates and Generator

This directory contains HTML templates for certificates and the Python script to generate them as PDFs.

## Templates

- `basic_template.html` - A simple, elegant certificate design
- `professional_template.html` - A professional-looking certificate for formal events
- `academic_template.html` - A certificate suitable for educational achievements

## Generator Script

The `certificateGenerator.py` script can be used to generate PDF certificates from HTML templates.

### Usage

Single certificate:
```bash
python certificateGenerator.py <template_path> <output_dir> <event_title>
```

Batch generation:
```bash
python certificateGenerator.py <template_path> <output_dir> <event_title> <participants_file>
```

Participants file can be either:
- JSON file with array of names or objects with name/email
- Text file with one name per line

### Dependencies

- Python 3.x
- reportlab
- pyhtml2pdf (for HTML to PDF conversion)

Install dependencies:
```bash
pip install reportlab pyhtml2pdf
```

## Output

Generated certificates are saved in the specified output directory with filenames based on the participant names.