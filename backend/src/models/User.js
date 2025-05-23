const { Schema, model } = require('mongoose');

const userSchema = new Schema({
  document: { type: String, required: true, unique: true },
  password: { type: String, required: [true, 'La contraseña es obligatoria'], minlength: [8, 'La contraseña debe tener al menos 8 caracteres'] },
  createdAt: { type: Date, default: Date.now },
});

module.exports = model('User', userSchema);