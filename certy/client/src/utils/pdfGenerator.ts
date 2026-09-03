import { Document, Page, Text, View, StyleSheet, PDFDownloadLink } from '@react-pdf/renderer';

// Define styles for the PDF
const styles = StyleSheet.create({
  page: {
    flexDirection: 'row',
    backgroundColor: '#E4E4E4',
    padding: 30,
  },
  section: {
    margin: 10,
    padding: 10,
    flexGrow: 1
  },
  title: {
    fontSize: 24,
    textAlign: 'center',
    marginBottom: 20,
  },
  name: {
    fontSize: 18,
    textAlign: 'center',
    marginBottom: 10,
  },
  event: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 10,
  },
  date: {
    fontSize: 14,
    textAlign: 'center',
  }
});

// Certificate component for PDF generation
const CertificateDocument = ({ participantName, eventTitle, issueDate }: { 
  participantName: string; 
  eventTitle: string; 
  issueDate: Date; 
}) => (
  <Document>
    <Page size="A4" style={styles.page}>
      <View style={styles.section}>
        <Text style={styles.title}>Сертификат участника</Text>
        <Text style={styles.name}>{participantName}</Text>
        <Text style={styles.event}>успешно participated in</Text>
        <Text style={styles.event}>{eventTitle}</Text>
        <Text style={styles.date}>Дата: {issueDate.toLocaleDateString('ru-RU')}</Text>
        <Text style={styles.event}>Организатор: Certy</Text>
      </View>
    </Page>
  </Document>
);

export { CertificateDocument, styles };