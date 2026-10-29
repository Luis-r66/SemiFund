export type Member = { id: number; name: string; program: string; semester: number; active: boolean };
export type PayStatus = 'Pagado' | 'Pendiente' | 'Vencido';
export type Contribution = { id: number; memberId: number; month: string; amount: number; status: PayStatus };
export type Expense = { id: number; description: string; category: string; date: string; amount: number };

export const members: Member[] = [
  { id: 1, name: 'Valentina Ríos', program: 'Ingeniería de Sistemas', semester: 7, active: true },
  { id: 2, name: 'Santiago Morales', program: 'Ingeniería de Software', semester: 5, active: true },
  { id: 3, name: 'Camila Ortega', program: 'Ciencia de Datos', semester: 4, active: true },
  { id: 4, name: 'Andrés Gutiérrez', program: 'Ingeniería de Sistemas', semester: 9, active: false },
  { id: 5, name: 'Laura Peñaloza', program: 'Ingeniería Electrónica', semester: 6, active: true },
  { id: 6, name: 'Mateo Cárdenas', program: 'Ingeniería de Software', semester: 3, active: true },
];

export const contributions: Contribution[] = [
  { id: 1, memberId: 1, month: 'Octubre 2026', amount: 30000, status: 'Pagado' },
  { id: 2, memberId: 2, month: 'Octubre 2026', amount: 30000, status: 'Pendiente' },
  { id: 3, memberId: 3, month: 'Septiembre 2026', amount: 30000, status: 'Vencido' },
  { id: 4, memberId: 5, month: 'Octubre 2026', amount: 30000, status: 'Pagado' },
  { id: 5, memberId: 6, month: 'Octubre 2026', amount: 30000, status: 'Pendiente' },
  { id: 6, memberId: 1, month: 'Septiembre 2026', amount: 30000, status: 'Pagado' },
  { id: 7, memberId: 2, month: 'Agosto 2026', amount: 30000, status: 'Vencido' },
  { id: 8, memberId: 1, month: 'Agosto 2026', amount: 30000, status: 'Pagado' },
  { id: 9, memberId: 5, month: 'Septiembre 2026', amount: 30000, status: 'Pagado' },
];

export const expenses: Expense[] = [
  { id: 1, description: 'Dominio y hosting del sitio', category: 'Infraestructura', date: '28 sep 2026', amount: 185000 },
  { id: 2, description: 'Refrigerios hackathon interna', category: 'Eventos', date: '20 sep 2026', amount: 142000 },
  { id: 3, description: 'Impresión de afiches', category: 'Difusión', date: '12 sep 2026', amount: 48000 },
  { id: 4, description: 'Licencia herramienta de diseño', category: 'Software', date: '02 sep 2026', amount: 95000 },
];

export const categories = ['Infraestructura', 'Eventos', 'Difusión', 'Software', 'Materiales', 'Otros'];
export const BALANCE = 480000;
export const TOTAL_CONTRIBUTED = 1250000;

export const cop = (n: number) => '$' + new Intl.NumberFormat('es-CO').format(n);
export const memberName = (id: number) => members.find((m) => m.id === id)?.name ?? '—';
