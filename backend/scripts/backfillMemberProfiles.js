const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const User = require('../models/User');
const Membership = require('../models/Membership');
const Member = require('../models/Member');
const { academicFieldsFromUser } = require('../utils/memberSync');

const dryRun = process.argv.includes('--dry-run');

async function main() {
  if (!process.env.MONGODB_URI) {
    console.error('MONGODB_URI no está configurada.');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGODB_URI);

  const memberships = await Membership.find({ memberId: { $ne: null } }).populate('userId');
  let actualizados = 0;
  let omitidos = 0;

  for (const membership of memberships) {
    if (!membership.userId || !membership.memberId) {
      omitidos++;
      continue;
    }

    const fields = {
      ...academicFieldsFromUser(membership.userId),
      userId: membership.userId._id
    };

    if (dryRun) {
      console.log('[dry-run]', membership.userId.email, fields.programa, fields.semestre);
    } else {
      await Member.updateOne({ _id: membership.memberId }, { $set: fields });
    }
    actualizados++;
  }

  console.log(dryRun ? 'Simulación terminada.' : 'Migración terminada.');
  console.log('Actualizados:', actualizados, 'Omitidos:', omitidos);
  await mongoose.disconnect();
}

main().catch(async (error) => {
  console.error('Error en la migración:', error.message);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
