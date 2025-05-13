const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const User = require('../models/User');

// Función de logger mejorada
function logRequest(message, data) {
  console.log(`========== ${message} ==========`);
  console.log(JSON.stringify(data, null, 2));
  console.log('================================');
}

// POST /api/users → Registrar nuevo usuario
router.post('/', async (req, res) => {
  try {
    const { document, password, confirmPassword } = req.body;

    logRequest('Datos recibidos en registro', req.body);

    // Verificar que todos los campos estén presentes
    if (!document || !password || !confirmPassword) {
      return res.status(400).json({ message: 'Por favor, completa todos los campos' });
    }

    // Validar que la contraseña tenga mínimo 8 caracteres
    if (password.length < 8) {
      return res.status(400).json({ message: 'La contraseña debe tener al menos 8 caracteres' });
    }

    // Validar que las contraseñas coincidan
    if (password !== confirmPassword) {
      return res.status(400).json({ message: 'Las contraseñas no coinciden' });
    }

    // Verificar si el documento ya está en uso
    const existingUser = await User.findOne({ document });
    if (existingUser) {
      return res.status(400).json({ message: 'El documento ya está en uso' });
    }

    // Hash de la contraseña antes de guardar
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear y guardar el usuario en MongoDB
    const newUser = new User({ document, password: hashedPassword });
    await newUser.save();

    logRequest('Usuario registrado', { document });
    res.status(201).json({ message: 'Usuario registrado exitosamente' });
  } catch (error) {
    console.error('Error en registro:', error);
    res.status(500).json({ message: 'Error del servidor', error: error.message });
  }
});

// POST /api/users/login → Iniciar sesión de usuario
router.post('/login', async (req, res) => {
  try {
    logRequest('Datos recibidos en login', req.body);

    const { document, password } = req.body;

    if (!document || !password) {
      return res.status(400).json({ message: 'Por favor, ingresa tu documento y contraseña' });
    }

    const user = await User.findOne({ document });
    if (!user) {
      console.log(`Login fallido: Usuario con documento ${document} no encontrado`);
      return res.status(400).json({ message: 'Usuario no encontrado' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      console.log(`Login fallido: Contraseña incorrecta para documento ${document}`);
      return res.status(400).json({ message: 'Contraseña incorrecta' });
    }

    console.log(`Login exitoso: Usuario con documento ${document}`);
    res.status(200).json({ message: 'Inicio de sesión exitoso' });
  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({ message: 'Error del servidor', error: error.message });
  }
});

// GET /api/users → Listar todos los usuarios
router.get('/', async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener usuarios', error: error.message });
  }
});

module.exports = router;