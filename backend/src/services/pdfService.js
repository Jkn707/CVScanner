// services/pdfService.js
const axios = require('axios');
const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

class PDFService {
  constructor() {
    this.apiKey = process.env.APITEMPLATE_API_KEY;
    this.templateId = process.env.APITEMPLATE_TEMPLATE_ID;
    this.outputDir = path.resolve(__dirname, '../output');
    
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }
  }

  /**
   * Genera un PDF usando APITemplate.io con los datos estructurados del CV
   * @param {Object} resumeData - Datos estructurados del CV
   * @param {string} ownerDocument - Documento de identidad del propietario
   * @returns {Promise<{filePath: string, pdfUrl: string}>}
   */
  async generatePDF(resumeData, ownerDocument) {
    try {
      // Verificar que tenemos las credenciales necesarias
      if (!this.apiKey || !this.templateId) {
        throw new Error('APITemplate credentials missing. Check your .env file.');
      }

      // Preparar payload para APITemplate
      const payload = {
        template_id: this.templateId,
        data: resumeData,
        expiration: 86400 // 24 horas para la URL
      };

      // Hacer solicitud a APITemplate.io
      const response = await axios.post(
        'https://api.apitemplate.io/v1/create',
        payload,
        {
          headers: {
            'X-API-KEY': this.apiKey,
            'Content-Type': 'application/json'
          }
        }
      );

      // Verificar respuesta
      if (response.status !== 200 || !response.data?.download_url) {
        throw new Error(`API error: ${JSON.stringify(response.data)}`);
      }

      // Guardar la URL del PDF
      const pdfUrl = response.data.download_url;
      
      // Descargar el PDF localmente
      const pdfResponse = await axios.get(pdfUrl, { responseType: 'arraybuffer' });
      const pdfFileName = `cv_${ownerDocument}_${Date.now()}.pdf`;
      const pdfPath = path.join(this.outputDir, pdfFileName);
      
      fs.writeFileSync(pdfPath, pdfResponse.data);
      console.log(`✔ PDF guardado en ${pdfPath}`);

      return {
        filePath: pdfPath,
        pdfUrl: pdfUrl
      };
    } catch (error) {
      console.error('Error en generatePDF:', error.response?.data || error.message);
      throw error;
    }
  }
}

module.exports = new PDFService();