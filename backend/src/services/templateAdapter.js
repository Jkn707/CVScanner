// services/templateAdapter.js
const fs = require('fs');
const path = require('path');
const PizZip = require('pizzip');
const Docxtemplater = require('docxtemplater');

/**
 * Service to adapt AI-formatted resume data to different document templates
 */
class TemplateAdapterService {
  constructor() {
    this.templatesDir = path.resolve(__dirname, '../templates');
  }

  /**
   * Lists available templates in the templates directory
   * @returns {Array} List of template files
   */
  getAvailableTemplates() {
    try {
      const files = fs.readdirSync(this.templatesDir);
      return files.filter(file => 
        file.endsWith('.docx') || file.endsWith('.pdf')
      );
    } catch (error) {
      console.error('Error reading templates directory:', error);
      return [];
    }
  }

  /**
   * Adapts formatted resume data to the specified template
   * @param {Object} formattedData - Structured resume data from AI analysis
   * @param {string} templateName - Name of the template file
   * @param {string} outputPath - Path where the filled template will be saved
   * @returns {string} Path to the generated document
   */
  adaptToTemplate(formattedData, templateName, outputPath) {
    const templatePath = path.join(this.templatesDir, templateName);
    
    if (!fs.existsSync(templatePath)) {
      throw new Error(`Template ${templateName} not found`);
    }
    
    // Handle different file types
    if (templateName.endsWith('.docx')) {
      return this._processDocxTemplate(formattedData, templatePath, outputPath);
    } else if (templateName.endsWith('.pdf')) {
      // For PDF implementation, we'd need additional libraries
      throw new Error('PDF template adaptation not yet implemented');
    } else {
      throw new Error('Unsupported template format');
    }
  }

  /**
   * Processes a DOCX template with the formatted data
   * @private
   */
  _processDocxTemplate(data, templatePath, outputPath) {
    try {
      const content = fs.readFileSync(templatePath, 'binary');
      const zip = new PizZip(content);
      
      const doc = new Docxtemplater(zip, {
        paragraphLoop: true,
        linebreaks: true,
      });

      // Prepare data for template
      const templateData = this._prepareDataForTemplate(data);
      
      doc.setData(templateData);
      doc.render();

      // Ensure output directory exists
      const outputDir = path.dirname(outputPath);
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      // Generate and save the document
      const buf = doc.getZip().generate({ type: 'nodebuffer' });
      fs.writeFileSync(outputPath, buf);
      
      return outputPath;
    } catch (error) {
      console.error('Error processing DOCX template:', error);
      throw error;
    }
  }

  /**
   * Prepares the AI-formatted data for template insertion
   * Handles special formatting or conversions needed for templates
   * @private
   */
  _prepareDataForTemplate(data) {
    // Create a copy to avoid modifying the original data
    const templateData = { ...data };
    
    // Handle potential missing data to avoid template errors
    const defaults = {
      fullName: '',
      profession: '',
      summary: '',
      contact: { address: '', email: '', website: '' },
      expertise: [],
      keyAchievements: [],
      experience: [],
      education: [],
      languages: [],
      certifications: [],
      awards: []
    };
    
    // Merge defaults with available data
    return { ...defaults, ...templateData };
  }
}

module.exports = new TemplateAdapterService();