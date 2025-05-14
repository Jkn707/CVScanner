const express = require('express');
const path = require('path');
const fs = require('fs');
const TemplateAdapterService = require('../services/templateAdapter');
const Resume = require('../models/Resume');

const router = express.Router();

// GET /api/templates - List available templates
router.get('/', async (req, res) => {
  try {
    const templates = TemplateAdapterService.getAvailableTemplates();
    res.status(200).json({ templates });
  } catch (error) {
    console.error('Error listing templates:', error);
    res.status(500).json({ message: 'Error listing templates', error: error.message });
  }
});

// POST /api/templates/generate/:resumeId - Generate document from resume and template
router.post('/generate/:resumeId', async (req, res) => {
  try {
    const { resumeId } = req.params;
    const { templateName } = req.body;
    
    if (!templateName) {
      return res.status(400).json({ message: 'Template name is required' });
    }
    
    // Retrieve the resume data
    const resume = await Resume.findById(resumeId);
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }
    
    if (!resume.formatted) {
      return res.status(400).json({ message: 'Resume has not been analyzed yet' });
    }
    
    // Generate unique filename for the output
    const outputFileName = `${resume.ownerDocument}_${Date.now()}_${path.basename(templateName)}`;
    const outputPath = path.resolve(__dirname, '../output', outputFileName);
    
    // Generate document from template
    const resultPath = TemplateAdapterService.adaptToTemplate(
      resume.formatted,
      templateName,
      outputPath
    );
    
    // Update resume with the generated document path
    resume.generatedDocxPath = resultPath;
    await resume.save();
    
    res.status(200).json({
      message: 'Resume template generated successfully',
      fileName: outputFileName,
      downloadUrl: `/api/templates/download/${resume._id}/${outputFileName}`
    });
  } catch (error) {
    console.error('Error generating from template:', error);
    res.status(500).json({ message: 'Error generating document', error: error.message });
  }
});

// GET /api/templates/download/:resumeId/:fileName - Download generated document
router.get('/download/:resumeId/:fileName', async (req, res) => {
  try {
    const { resumeId, fileName } = req.params;
    const filePath = path.resolve(__dirname, '../output', fileName);
    
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ message: 'File not found' });
    }
    
    res.download(filePath);
  } catch (error) {
    console.error('Error downloading file:', error);
    res.status(500).json({ message: 'Error downloading file', error: error.message });
  }
});

module.exports = router;