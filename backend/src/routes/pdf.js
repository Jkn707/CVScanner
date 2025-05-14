// routes/pdf.js
const express = require('express');
const router = express.Router();
const Resume = require('../models/Resume');
const PDFService = require('../services/pdfService');
const path = require('path');

// POST /api/pdf/generate/:resumeId - Generate PDF for a resume
router.post('/generate/:resumeId', async (req, res) => {
  try {
    const { resumeId } = req.params;
    const resume = await Resume.findById(resumeId);
    
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }
    
    if (!resume.formatted) {
      return res.status(400).json({ 
        message: 'Resume has not been analyzed yet',
        resumeId
      });
    }

    // Generar PDF con APITemplate
    const { filePath, pdfUrl } = await PDFService.generatePDF(
      resume.formatted,
      resume.ownerDocument
    );

    // Actualizar documento en MongoDB con la URL del PDF
    await Resume.findByIdAndUpdate(resumeId, {
      pdfPath: filePath,
      pdfUrl: pdfUrl
    });

    res.status(200).json({
      message: 'PDF generated successfully',
      resumeId,
      pdfUrl,
      downloadUrl: `/api/pdf/download/${resumeId}`
    });
  } catch (error) {
    console.error('Error generating PDF:', error);
    
    if (error.response) {
      const { status, data } = error.response;
      if (status === 401) {
        return res.status(500).json({
          message: 'API authentication error. Check your APITemplate API key.',
          error: 'AUTH_ERROR'
        });
      }
    }
    
    res.status(500).json({
      message: 'Error generating PDF',
      error: error.message
    });
  }
});

// GET /api/pdf/download/:resumeId - Download PDF
router.get('/download/:resumeId', async (req, res) => {
  try {
    const { resumeId } = req.params;
    const resume = await Resume.findById(resumeId);
    
    if (!resume || !resume.pdfPath) {
      return res.status(404).json({ message: 'PDF not found for this resume' });
    }

    res.download(resume.pdfPath);
  } catch (error) {
    console.error('Error downloading PDF:', error);
    res.status(500).json({
      message: 'Error downloading PDF',
      error: error.message
    });
  }
});

module.exports = router;