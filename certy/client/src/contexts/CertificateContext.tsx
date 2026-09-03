import React, { createContext, useContext, useState, ReactNode } from 'react';

interface CertificateContextType {
  certificates: any[];
  addCertificate: (certificate: any) => void;
  removeCertificate: (id: string) => void;
  clearCertificates: () => void;
}

const CertificateContext = createContext<CertificateContextType | undefined>(undefined);

export function CertificateProvider({ children }: { children: ReactNode }) {
  const [certificates, setCertificates] = useState<any[]>([]);

  const addCertificate = (certificate: any) => {
    setCertificates(prev => [...prev, certificate]);
  };

  const removeCertificate = (id: string) => {
    setCertificates(prev => prev.filter(cert => cert.id !== id));
  };

  const clearCertificates = () => {
    setCertificates([]);
  };

  return (
    <CertificateContext.Provider value={{ 
      certificates, 
      addCertificate, 
      removeCertificate, 
      clearCertificates 
    }}>
      {children}
    </CertificateContext.Provider>
  );
}

export function useCertificate() {
  const context = useContext(CertificateContext);
  if (context === undefined) {
    throw new Error('useCertificate must be used within a CertificateProvider');
  }
  return context;
}