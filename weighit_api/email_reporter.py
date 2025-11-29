"""
Email reporting functionality for WeighIt.
Sends formatted reports via Gmail SMTP.
"""
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import tomli
from pathlib import Path


def load_email_config():
    """Load email configuration from secrets.toml"""
    secrets_path = Path(__file__).parent / 'secrets.toml'
    
    if not secrets_path.exists():
        raise FileNotFoundError(f"secrets.toml not found at {secrets_path}")
    
    with open(secrets_path, 'rb') as f:
        config = tomli.load(f)
    
    return config['email']


def send_report_email(recipient: str, subject: str, body: str, csv_data: str = None):
    """
    Send an email report with optional CSV attachment.
    
    Args:
        recipient: Email address to send to
        subject: Email subject line
        body: Email body text
        csv_data: Optional CSV data to attach
    """
    config = load_email_config()
    
    # Create message
    msg = MIMEMultipart()
    msg['From'] = config['sender_email']
    msg['To'] = recipient
    msg['Subject'] = subject
    
    # Add body
    msg.attach(MIMEText(body, 'plain'))
    
    # Add CSV attachment if provided
    if csv_data:
        attachment = MIMEText(csv_data, 'csv')
        attachment.add_header('Content-Disposition', 'attachment', filename='weighit_report.csv')
        msg.attach(attachment)
    
    # Send email
    try:
        with smtplib.SMTP(config['smtp_server'], config['smtp_port']) as server:
            server.starttls()
            server.login(config['sender_email'], config['sender_password'])
            server.send_message(msg)
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        raise
