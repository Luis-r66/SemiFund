import { useState, type ReactNode } from 'react';
import { AppBar, Button, Card, Field, SearchBar, SectionLabel, Select, StatusBadge, Tabs, TextInput } from './components/ui';
import { BALANCE, TOTAL_CONTRIBUTED, categories, contributions, cop, expenses, memberName, members } from './data';

export type Route =
  | { name: 'home' }
  | { name: 'members' }
  | { name: 'member'; id: number }
  | { name: 'memberForm'; id?: number }
  | { name: 'contributions' }
  | { name: 'contributionForm' }
  | { name: 'expenses' }
  | { name: 'expenseForm' };

type Nav = { go: (r: Route) => void; back: () => void };

const Body = ({ children }: { children: ReactNode }) => (
  <div className="no-scrollbar flex-1 overflow-y-auto px-4 pb-6">{children}</div>
);
const Footer = ({ children }: { children: ReactNode }) => (
  <div className="shrink-0 space-y-2 border-t border-line bg-paper px-4 pt-3 pb-4">{children}</div>
);
const initials = (n: string) => n.split(' ').map((p) => p[0]).slice(0, 2).join('');
const Avatar = ({ name, dim }: { name: string; dim?: boolean }) => (
  <div className={`grid size-11 shrink-0 place-items-center rounded-full text-[14px] font-semibold ${dim ? 'bg-mist text-ink-3' : 'bg-ink text-white'}`}>
    {initials(name)}
  </div>
);

export function Home({ go }: Nav) {
  const pending = contributions.filter((c) => c.status !== 'Pagado').length;
  const nav = [
    { label: 'Integrantes', meta: `${members.filter((m) => m.active).length} activos`, r: { name: 'members' } as Route, icon: <><circle cx="9" cy="8" r="3.5" /><path d="M2.5 20c.6-3.5 3.3-5.5 6.5-5.5s5.9 2 6.5 5.5M16 4.5a3.5 3.5 0 010 7M18 14.5c2 .6 3.2 2.5 3.5 5.5" /></> },
    { label: 'Aportes', meta: `${pending} por cobrar`, r: { name: 'contributions' } as Route, icon: <><rect x="3" y="6" width="18" height="13" rx="2.5" /><path d="M3 10h18M7 15h3" /></> },
    { label: 'Gastos', meta: `${expenses.length} este mes`, r: { name: 'expenses' } as Route, icon: <><path d="M6 3h12v18l-3-2-3 2-3-2-3 2z" /><path d="M9 8h6M9 12h6" /></> },
  ];
  return (
    <>
      <div className="flex h-14 shrink-0 items-center justify-between px-4">
        <div>
          <p className="text-[12px] font-medium text-ink-3">Tesorería de semilleros</p>
          <h1 className="text-[19px] font-semibold tracking-tight">SemiFund</h1>
        </div>
        <div className="grid size-10 place-items-center rounded-full bg-mist text-[13px] font-semibold">VR</div>
      </div>
      <Body>
        <div className="mt-3 rounded-3xl bg-ink p-5 text-white">
          <p className="text-[13px] font-medium text-white/60">Saldo disponible</p>
          <p className="mt-2 font-mono text-[34px] leading-none font-medium tracking-tight tabular-nums">{cop(BALANCE)}</p>
          <p className="mt-4 inline-flex items-center gap-1.5 rounded-full bg-white/10 px-2.5 py-1 text-[12px] font-medium">
            <span className="size-1.5 rounded-full bg-[#5fd38d]" /> Actualizado hoy, 4 oct
          </p>
        </div>
        <Card className="mt-3">
          <div className="flex items-end justify-between">
            <div>
              <p className="text-[13px] font-medium text-ink-2">Total aportado</p>
              <p className="mt-1.5 font-mono text-[24px] leading-none font-medium tracking-tight tabular-nums">{cop(TOTAL_CONTRIBUTED)}</p>
            </div>
            <span className="text-[12px] font-semibold text-ok">+ {cop(60000)} oct</span>
          </div>
          <div className="mt-4 h-1.5 overflow-hidden rounded-full bg-mist">
            <div className="h-full w-[62%] rounded-full bg-ok" />
          </div>
          <p className="mt-2 text-[12px] text-ink-3">62% de la meta semestral ({cop(2000000)})</p>
        </Card>

        <div className="mt-7">
          <SectionLabel>Gestionar</SectionLabel>
          <div className="space-y-2">
            {nav.map((n) => (
              <Card key={n.label} onClick={() => go(n.r)}>
                <div className="flex items-center gap-4">
                  <div className="grid size-11 place-items-center rounded-xl bg-mist">
                    <svg viewBox="0 0 24 24" className="size-5.5" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">{n.icon}</svg>
                  </div>
                  <div className="flex-1">
                    <p className="text-[16px] font-semibold">{n.label}</p>
                    <p className="text-[13px] text-ink-2">{n.meta}</p>
                  </div>
                  <svg viewBox="0 0 24 24" className="size-5 text-ink-3" fill="none" stroke="currentColor" strokeWidth={2}><path d="M9 6l6 6-6 6" /></svg>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </Body>
    </>
  );
}

export function Members({ go, back }: Nav) {
  const [q, setQ] = useState('');
  const list = members.filter((m) => (m.name + m.program).toLowerCase().includes(q.toLowerCase()));
  return (
    <>
      <AppBar title="Integrantes" onBack={back} onAdd={() => go({ name: 'memberForm' })} />
      <div className="shrink-0 px-4 pb-3">
        <SearchBar value={q} onChange={setQ} />
      </div>
      <Body>
        <SectionLabel>{list.length} integrantes</SectionLabel>
        <div className="space-y-2">
          {list.map((m) => (
            <Card key={m.id} onClick={() => go({ name: 'member', id: m.id })}>
              <div className="flex items-center gap-3">
                <Avatar name={m.name} dim={!m.active} />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[15px] font-semibold">{m.name}</p>
                  <p className="truncate text-[13px] text-ink-2">{m.program} · {m.semester}° sem.</p>
                </div>
                <StatusBadge status={m.active ? 'Activo' : 'Inactivo'} />
              </div>
            </Card>
          ))}
          {list.length === 0 && <p className="py-10 text-center text-[14px] text-ink-3">Sin resultados para "{q}"</p>}
        </div>
      </Body>
    </>
  );
}

export function MemberDetail({ id, go, back }: Nav & { id: number }) {
  const m = members.find((x) => x.id === id) ?? members[0];
  const [active, setActive] = useState(m.active);
  const hist = contributions.filter((c) => c.memberId === m.id);
  return (
    <>
      <AppBar title="Integrante" onBack={back} />
      <Body>
        <div className="flex flex-col items-center pt-2 pb-6 text-center">
          <div className={`grid size-18 place-items-center rounded-full text-[22px] font-semibold ${active ? 'bg-ink text-white' : 'bg-mist text-ink-3'}`}>{initials(m.name)}</div>
          <h2 className="mt-3 text-[21px] font-semibold tracking-tight">{m.name}</h2>
          <div className="mt-2"><StatusBadge status={active ? 'Activo' : 'Inactivo'} /></div>
        </div>
        <Card className="!p-0">
          <div className="grid grid-cols-[1fr_auto] divide-x divide-line">
            <div className="p-4">
              <p className="text-[12px] text-ink-3">Programa</p>
              <p className="mt-0.5 text-[15px] font-semibold">{m.program}</p>
            </div>
            <div className="p-4 pr-6">
              <p className="text-[12px] text-ink-3">Semestre</p>
              <p className="mt-0.5 text-[15px] font-semibold">{m.semester}°</p>
            </div>
          </div>
        </Card>
        <div className="mt-6">
          <SectionLabel>Historial de aportes</SectionLabel>
          <Card className="!py-1">
            {hist.length === 0 && <p className="py-4 text-[14px] text-ink-3">Aún no registra aportes.</p>}
            {hist.map((c, i) => (
              <div key={c.id} className={`flex items-center gap-3 py-3 ${i ? 'border-t border-line' : ''}`}>
                <div className="flex-1">
                  <p className="text-[15px] font-medium">{c.month}</p>
                  <p className="font-mono text-[13px] text-ink-2 tabular-nums">{cop(c.amount)}</p>
                </div>
                <StatusBadge status={c.status} />
              </div>
            ))}
          </Card>
        </div>
      </Body>
      <Footer>
        <div className="grid grid-cols-2 gap-2">
          <Button variant="outline" onClick={() => go({ name: 'memberForm', id: m.id })}>Editar</Button>
          <Button variant="danger" onClick={() => setActive(!active)}>{active ? 'Desactivar' : 'Reactivar'}</Button>
        </div>
      </Footer>
    </>
  );
}

export function MemberForm({ id, back }: Nav & { id?: number }) {
  const m = members.find((x) => x.id === id);
  const [name, setName] = useState(m?.name ?? '');
  const [program, setProgram] = useState(m?.program ?? '');
  const [sem, setSem] = useState(m ? String(m.semester) : '');
  const ok = name.trim() && program.trim() && sem;
  return (
    <>
      <AppBar title={m ? 'Editar integrante' : 'Nuevo integrante'} onBack={back} />
      <Body>
        <div className="space-y-5 pt-2">
          <Field label="Nombre completo"><TextInput value={name} onChange={(e) => setName(e.target.value)} placeholder="Ej. Juliana Herrera" /></Field>
          <Field label="Programa académico"><TextInput value={program} onChange={(e) => setProgram(e.target.value)} placeholder="Ej. Ingeniería de Sistemas" /></Field>
          <Field label="Semestre"><TextInput value={sem} onChange={(e) => setSem(e.target.value.replace(/\D/g, '').slice(0, 2))} inputMode="numeric" placeholder="1 – 10" /></Field>
        </div>
      </Body>
      <Footer><Button disabled={!ok} onClick={back}>Guardar</Button></Footer>
    </>
  );
}

type Filter = 'Todos' | 'Pendiente' | 'Vencido';
export function Contributions({ go, back }: Nav) {
  const [f, setF] = useState<Filter>('Todos');
  const list = contributions.filter((c) => f === 'Todos' || c.status === f);
  return (
    <>
      <AppBar title="Aportes" onBack={back} onAdd={() => go({ name: 'contributionForm' })} />
      <div className="shrink-0 px-4 pb-3"><Tabs tabs={['Todos', 'Pendiente', 'Vencido'] as Filter[]} value={f} onChange={setF} /></div>
      <Body>
        <SectionLabel>{list.length} registros</SectionLabel>
        <div className="space-y-2">
          {list.map((c) => (
            <Card key={c.id}>
              <div className="flex items-center gap-3">
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[15px] font-semibold">{memberName(c.memberId)}</p>
                  <p className="text-[13px] text-ink-2">{c.month}</p>
                </div>
                <div className="flex flex-col items-end gap-1.5">
                  <p className="font-mono text-[15px] font-medium tabular-nums">{cop(c.amount)}</p>
                  <StatusBadge status={c.status} />
                </div>
              </div>
            </Card>
          ))}
        </div>
      </Body>
    </>
  );
}

const months = ['Agosto 2026', 'Septiembre 2026', 'Octubre 2026', 'Noviembre 2026'];
const digits = (s: string) => Number(s.replace(/\D/g, '')) || 0;

export function ContributionForm({ back }: Nav) {
  const [member, setMember] = useState('');
  const [month, setMonth] = useState('Octubre 2026');
  const [amount, setAmount] = useState('30.000');
  return (
    <>
      <AppBar title="Registrar aporte" onBack={back} />
      <Body>
        <div className="space-y-5 pt-2">
          <Field label="Integrante"><Select value={member} onChange={setMember} options={members.filter((m) => m.active).map((m) => m.name)} placeholder="Selecciona un integrante" /></Field>
          <Field label="Mes"><Select value={month} onChange={setMonth} options={months} placeholder="Selecciona el mes" /></Field>
          <Field label="Monto (COP)"><MoneyInput value={amount} onChange={setAmount} /></Field>
        </div>
      </Body>
      <Footer><Button disabled={!member || !digits(amount)} onClick={back}>Registrar aporte</Button></Footer>
    </>
  );
}

function MoneyInput({ value, onChange, invalid }: { value: string; onChange: (v: string) => void; invalid?: boolean }) {
  return (
    <div className="relative">
      <span className="absolute top-1/2 left-4 -translate-y-1/2 font-mono text-[15px] text-ink-3">$</span>
      <div className="[&_input]:pl-8 [&_input]:font-mono">
        <TextInput
          invalid={invalid}
          inputMode="numeric"
          placeholder="0"
          value={value}
          onChange={(e) => {
            const n = digits(e.target.value);
            onChange(n ? new Intl.NumberFormat('es-CO').format(n) : '');
          }}
        />
      </div>
    </div>
  );
}

export function Expenses({ go, back }: Nav) {
  const total = expenses.reduce((s, e) => s + e.amount, 0);
  return (
    <>
      <AppBar title="Gastos" onBack={back} onAdd={() => go({ name: 'expenseForm' })} />
      <Body>
        <div className="mb-5 flex items-baseline justify-between px-1">
          <p className="text-[13px] text-ink-2">Total septiembre</p>
          <p className="font-mono text-[17px] font-medium tabular-nums">{cop(total)}</p>
        </div>
        <div className="space-y-2">
          {expenses.map((e) => (
            <Card key={e.id}>
              <div className="flex items-start gap-3">
                <div className="min-w-0 flex-1">
                  <p className="text-[15px] font-semibold">{e.description}</p>
                  <div className="mt-2 flex items-center gap-2 text-[12px]">
                    <span className="rounded-md bg-mist px-2 py-0.5 font-medium text-ink-2">{e.category}</span>
                    <span className="text-ink-3">{e.date}</span>
                  </div>
                </div>
                <p className="font-mono text-[15px] font-medium text-bad tabular-nums">−{cop(e.amount)}</p>
              </div>
            </Card>
          ))}
        </div>
      </Body>
    </>
  );
}

export function ExpenseForm({ back }: Nav) {
  const [desc, setDesc] = useState('');
  const [cat, setCat] = useState('');
  const [amount, setAmount] = useState('520.000');
  const n = digits(amount);
  const over = n > BALANCE;
  return (
    <>
      <AppBar title="Nuevo gasto" onBack={back} />
      <Body>
        <div className="space-y-5 pt-2">
          <Field label="Descripción"><TextInput value={desc} onChange={(e) => setDesc(e.target.value)} placeholder="Ej. Camisetas del semillero" /></Field>
          <Field label="Categoría"><Select value={cat} onChange={setCat} options={categories} placeholder="Selecciona una categoría" /></Field>
          <Field label="Monto (COP)" error={over ? `Saldo insuficiente. Disponible: ${cop(BALANCE)}` : undefined}>
            <MoneyInput value={amount} onChange={setAmount} invalid={over} />
          </Field>
          {!over && n > 0 && <p className="px-1 text-[13px] text-ink-2">Saldo tras el gasto: <span className="font-mono text-ok tabular-nums">{cop(BALANCE - n)}</span></p>}
        </div>
      </Body>
      <Footer><Button disabled={over || !n || !desc.trim() || !cat} onClick={back}>Guardar gasto</Button></Footer>
    </>
  );
}
