import type { ReactNode, InputHTMLAttributes } from 'react';

export function AppBar({ title, onBack, onAdd }: { title: string; onBack?: () => void; onAdd?: () => void }) {
  return (
    <header className="flex h-14 shrink-0 items-center gap-1 px-2">
      {onBack ? (
        <IconBtn label="Atrás" onClick={onBack}>
          <path d="M15 5l-7 7 7 7" />
        </IconBtn>
      ) : (
        <div className="w-2" />
      )}
      <h1 className="flex-1 truncate px-1 text-[19px] font-semibold tracking-tight">{title}</h1>
      {onAdd && (
        <button
          onClick={onAdd}
          aria-label="Agregar"
          className="mr-1 grid size-10 place-items-center rounded-full bg-ink text-white transition hover:bg-ink/85 active:scale-95"
        >
          <svg viewBox="0 0 24 24" className="size-5" fill="none" stroke="currentColor" strokeWidth={2.2} strokeLinecap="round">
            <path d="M12 5v14M5 12h14" />
          </svg>
        </button>
      )}
    </header>
  );
}

export function IconBtn({ label, onClick, children }: { label: string; onClick: () => void; children: ReactNode }) {
  return (
    <button onClick={onClick} aria-label={label} className="grid size-10 place-items-center rounded-full text-ink transition hover:bg-mist">
      <svg viewBox="0 0 24 24" className="size-5" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
        {children}
      </svg>
    </button>
  );
}

export function Card({ children, onClick, className = '' }: { children: ReactNode; onClick?: () => void; className?: string }) {
  const base = `block w-full rounded-2xl border border-line bg-paper p-4 text-left ${className}`;
  return onClick ? (
    <button onClick={onClick} className={`${base} transition hover:border-ink-3 active:scale-[0.99]`}>
      {children}
    </button>
  ) : (
    <div className={base}>{children}</div>
  );
}

const tones = {
  ok: 'bg-ok-soft text-ok',
  warn: 'bg-warn-soft text-warn',
  bad: 'bg-bad-soft text-bad',
  muted: 'bg-mist text-ink-2',
};
const statusTone: Record<string, keyof typeof tones> = {
  Activo: 'ok',
  Pagado: 'ok',
  Pendiente: 'warn',
  Vencido: 'bad',
  Inactivo: 'muted',
};

export function StatusBadge({ status }: { status: string }) {
  const t = statusTone[status] ?? 'muted';
  return (
    <span className={`inline-flex shrink-0 items-center gap-1.5 rounded-full px-2.5 py-1 text-[12px] font-semibold ${tones[t]}`}>
      <span className="size-1.5 rounded-full bg-current" />
      {status}
    </span>
  );
}

export function Field({ label, error, children }: { label: string; error?: string; children: ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] font-medium text-ink-2">{label}</span>
      {children}
      {error && (
        <span role="alert" className="mt-2 flex items-start gap-2 rounded-xl bg-bad-soft px-3 py-2.5 text-[13px] font-medium text-bad">
          <svg viewBox="0 0 24 24" className="mt-px size-4 shrink-0" fill="none" stroke="currentColor" strokeWidth={2.2} strokeLinecap="round">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 8v5M12 16.5v.01" />
          </svg>
          {error}
        </span>
      )}
    </label>
  );
}

const inputCls = (invalid?: boolean) =>
  `h-13 w-full rounded-xl border bg-paper px-4 text-[15px] outline-none transition placeholder:text-ink-3 focus:ring-4 ${
    invalid ? 'border-bad focus:ring-bad/15' : 'border-line focus:border-ink focus:ring-ink/8'
  }`;

export function TextInput({ invalid, ...p }: InputHTMLAttributes<HTMLInputElement> & { invalid?: boolean }) {
  return <input {...p} className={inputCls(invalid)} />;
}

export function Select({ value, onChange, options, placeholder }: { value: string; onChange: (v: string) => void; options: string[]; placeholder: string }) {
  return (
    <div className="relative">
      <select value={value} onChange={(e) => onChange(e.target.value)} className={`${inputCls()} appearance-none pr-10 ${value ? '' : 'text-ink-3'}`}>
        <option value="" disabled>
          {placeholder}
        </option>
        {options.map((o) => (
          <option key={o} value={o} className="text-ink">
            {o}
          </option>
        ))}
      </select>
      <svg viewBox="0 0 24 24" className="pointer-events-none absolute top-1/2 right-4 size-4 -translate-y-1/2 text-ink-2" fill="none" stroke="currentColor" strokeWidth={2}>
        <path d="M6 9l6 6 6-6" />
      </svg>
    </div>
  );
}

export function Button({ children, onClick, variant = 'primary', disabled }: { children: ReactNode; onClick?: () => void; variant?: 'primary' | 'outline' | 'danger'; disabled?: boolean }) {
  const v = {
    primary: 'bg-ink text-white hover:bg-ink/85',
    outline: 'border border-line bg-paper text-ink hover:border-ink-3',
    danger: 'border border-bad/30 bg-paper text-bad hover:bg-bad-soft',
  }[variant];
  return (
    <button onClick={onClick} disabled={disabled} className={`h-13 w-full rounded-xl text-[15px] font-semibold transition active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-35 ${v}`}>
      {children}
    </button>
  );
}

export function SearchBar({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <div className="relative">
      <svg viewBox="0 0 24 24" className="absolute top-1/2 left-4 size-4.5 -translate-y-1/2 text-ink-3" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round">
        <circle cx="11" cy="11" r="7" />
        <path d="M20 20l-3.5-3.5" />
      </svg>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Buscar integrante"
        className="h-12 w-full rounded-full bg-mist pr-4 pl-11 text-[15px] outline-none transition placeholder:text-ink-3 focus:bg-paper focus:ring-1 focus:ring-line"
      />
    </div>
  );
}

export function Tabs<T extends string>({ tabs, value, onChange }: { tabs: T[]; value: T; onChange: (t: T) => void }) {
  return (
    <div className="grid grid-flow-col gap-1 rounded-full bg-mist p-1">
      {tabs.map((t) => (
        <button
          key={t}
          onClick={() => onChange(t)}
          className={`h-9 rounded-full text-[14px] font-semibold transition ${value === t ? 'bg-paper text-ink shadow-[0_1px_2px_rgba(0,0,0,0.08)]' : 'text-ink-2 hover:text-ink'}`}
        >
          {t}
        </button>
      ))}
    </div>
  );
}

export function SectionLabel({ children }: { children: ReactNode }) {
  return <p className="mb-2 px-1 text-[12px] font-semibold tracking-[0.08em] text-ink-3 uppercase">{children}</p>;
}
