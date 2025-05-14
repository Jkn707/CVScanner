const { Router } = require('express');
const router = Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Tesseract = require('tesseract.js');

const Resume = require('../models/Resume');
const User = require('../models/User');
const generateResumeDocx = require('../services/generateDocx');
const AIAnalysisService = require('../services/aiAnalysis');
const PDFService = require('../services/pdfService');

const storage = multer.memoryStorage();
const upload = multer({ storage });

router.post('/upload', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No se ha subido ninguna imagen' });
    }

    const { ownerDocument, combinedText } = req.body;
    if (!ownerDocument) {
      return res.status(400).json({ message: 'Falta el número de cédula (ownerDocument)' });
    }

    const user = await User.findOne({ document: ownerDocument });
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado con esa cédula' });
    }

    const imageBase64 = req.file.buffer.toString('base64');
    const imageMimeType = req.file.mimetype;
    const imageData = `data:${imageMimeType};base64,${imageBase64}`;

    let extractedText = combinedText || '';
    if (!combinedText) {
      const result = await Tesseract.recognize(
        req.file.buffer,
        'spa',
        { logger: info => console.log(info) }
      );
      extractedText = result.data.text;
    }

    const resume = new Resume({
      user: user._id,
      ownerDocument,
      extractedText,
      originalImage: imageData,
      fileName: req.file.originalname
    });

    await resume.save();

    const { data: formatted } = await AIAnalysisService.analyzeResume(extractedText);

    // Generar DOCX
    const docxFileName = `cv_${ownerDocument}_${resume._id}.docx`;
    const docxPath = path.resolve(__dirname, '../output', docxFileName);
    generateResumeDocx(formatted, docxPath);

    // Generar PDF con APITemplate
    let pdfPath = '';
    let pdfUrl = '';
    try {
      const pdfResult = await PDFService.generatePDF(formatted, ownerDocument);
      pdfPath = pdfResult.filePath;
      pdfUrl = pdfResult.pdfUrl;
    } catch (pdfError) {
      console.error('Error generando PDF:', pdfError);
    }

    resume.formatted = formatted;
    resume.generatedDocxPath = docxPath;
    resume.pdfPath = pdfPath;
    resume.pdfUrl = pdfUrl;
    await resume.save();

    res.status(201).json({
      message: 'CV guardado y generado exitosamente',
      resume: {
        id: resume._id,
        extractedText,
        downloadDocxUrl: `/api/resumes/download/${resume._id}`,
        downloadPdfUrl: pdfUrl ? `/api/pdf/download/${resume._id}` : null
      }
    });
  } catch (error) {
    console.error('Error al procesar el CV:', error);
    res.status(500).json({ message: 'Error interno del servidor', error: error.message });
  }
});

router.get('/download/:id', async (req, res) => {
  try {
    const resume = await Resume.findById(req.params.id);
    if (!resume || !resume.generatedDocxPath) {
      return res.status(404).json({ message: 'Archivo no encontrado para este CV' });
    }

    res.download(resume.generatedDocxPath);
  } catch (error) {
    console.error('Error al descargar el documento:', error);
    res.status(500).json({ message: 'Error interno al intentar descargar', error: error.message });
  }
});

// GET /api/resumes/downloadPdf/:id - Descargar PDF
router.get('/downloadPdf/:id', async (req, res) => {
  try {
    const resume = await Resume.findById(req.params.id);
    if (!resume || !resume.pdfPath) {
      return res.status(404).json({ message: 'PDF no encontrado para este CV' });
    }

    res.download(resume.pdfPath);
  } catch (error) {
    console.error('Error al descargar el PDF:', error);
    res.status(500).json({ message: 'Error interno al intentar descargar el PDF', error: error.message });
  }
});

module.exports = router;
