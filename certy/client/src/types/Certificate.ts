export interface Certificate {
  id: string;
  userId: string;
  templateId: string;
  templateName: string;
  participantName: string;
  eventTitle: string;
  issueDate: Date;
  status: 'generated' | 'printed' | 'pending';
  filePath?: string;
}