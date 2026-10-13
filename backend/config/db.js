const mongoose = require('mongoose');

async function connectDB(uri) {
  if (!uri) {
    throw new Error('Falta MONGODB_URI en el archivo .env');
  }
  // Quita espacios accidentales al copiar la URI desde Atlas
  const cleanUri = String(uri).trim();
  await mongoose.connect(cleanUri, {
    serverSelectionTimeoutMS: 15000
  });
  console.log('MongoDB conectado:', mongoose.connection.name);
}

module.exports = connectDB;
