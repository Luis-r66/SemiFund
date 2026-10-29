import { useState } from 'react';
import { Contributions, ContributionForm, Expenses, ExpenseForm, Home, MemberDetail, MemberForm, Members, type Route } from './screens';

const index: { label: string; r: Route }[] = [
  { label: 'Inicio', r: { name: 'home' } },
  { label: 'Integrantes', r: { name: 'members' } },
  { label: 'Detalle de integrante', r: { name: 'member', id: 1 } },
  { label: 'Formulario de integrante', r: { name: 'memberForm' } },
  { label: 'Aportes', r: { name: 'contributions' } },
  { label: 'Formulario de aporte', r: { name: 'contributionForm' } },
  { label: 'Gastos', r: { name: 'expenses' } },
  { label: 'Formulario de gasto', r: { name: 'expenseForm' } },
];

export default function App() {
  const [stack, setStack] = useState<Route[]>([{ name: 'home' }]);
  const route = stack[stack.length - 1];
  const go = (r: Route) => setStack((s) => [...s, r]);
  const back = () => setStack((s) => (s.length > 1 ? s.slice(0, -1) : s));
  const nav = { go, back };
  const key = JSON.stringify(route);

  const screen = (() => {
    switch (route.name) {
      case 'home': return <Home {...nav} />;
      case 'members': return <Members {...nav} />;
      case 'member': return <MemberDetail {...nav} id={route.id} />;
      case 'memberForm': return <MemberForm {...nav} id={route.id} />;
      case 'contributions': return <Contributions {...nav} />;
      case 'contributionForm': return <ContributionForm {...nav} />;
      case 'expenses': return <Expenses {...nav} />;
      case 'expenseForm': return <ExpenseForm {...nav} />;
    }
  })();

  return (
    <main className="flex min-h-screen items-center justify-center gap-14 p-6">
      <aside className="hidden w-56 lg:block">
        <p className="text-[12px] font-semibold tracking-[0.08em] text-ink-3 uppercase">Pantallas</p>
        <ol className="mt-4 space-y-0.5">
          {index.map((s, i) => {
            const on = s.r.name === route.name;
            return (
              <li key={s.label}>
                <button
                  onClick={() => setStack(s.r.name === 'home' ? [s.r] : [{ name: 'home' }, s.r])}
                  className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-[14px] transition ${on ? 'bg-paper font-semibold text-ink' : 'text-ink-2 hover:text-ink'}`}
                >
                  <span className="w-4 font-mono text-[12px] text-ink-3">{i + 1}</span>
                  {s.label}
                </button>
              </li>
            );
          })}
        </ol>
      </aside>

      <div className="relative h-[800px] w-[380px] shrink-0 rounded-[44px] bg-[#1b1c1e] p-2.5 shadow-[0_30px_60px_-20px_rgba(0,0,0,0.35)]">
        <div className="flex h-full flex-col overflow-hidden rounded-[36px] bg-paper">
          <div className="relative flex h-9 shrink-0 items-center justify-between px-6 text-[13px] font-semibold">
            <span>9:41</span>
            <span className="absolute top-2.5 left-1/2 size-3.5 -translate-x-1/2 rounded-full bg-[#1b1c1e]" />
            <span className="flex items-center gap-1.5">
              <svg viewBox="0 0 24 24" className="size-3.5" fill="currentColor"><path d="M2 20h3v-4H2zm5 0h3v-8H7zm5 0h3V8h-3zm5 0h3V4h-3z" /></svg>
              <svg viewBox="0 0 24 24" className="size-4" fill="currentColor"><rect x="2" y="7" width="18" height="10" rx="2" /><rect x="21" y="10" width="1.5" height="4" rx=".5" /></svg>
            </span>
          </div>
          <div key={key} className="flex min-h-0 flex-1 flex-col animate-[fade_.22s_ease-out]">{screen}</div>
          <div className="flex h-6 shrink-0 items-center justify-center bg-paper">
            <span className="h-1 w-28 rounded-full bg-ink/80" />
          </div>
        </div>
      </div>
    </main>
  );
}
