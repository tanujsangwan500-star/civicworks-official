import { useState } from 'react';
import { LockKeyhole, ShieldCheck } from 'lucide-react';
import { useAuth } from '@/auth/AuthProvider';

export function LoginPage({ onBack }: { onBack: () => void }) {
  const { signIn } = useAuth(); const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [error, setError] = useState(''); const [busy, setBusy] = useState(false);
  async function submit(e: React.FormEvent) { e.preventDefault(); setBusy(true); setError(''); const message = await signIn(email, password); if (message) setError(message); setBusy(false); }
  return <section className="section narrow page"><div className="staff-lock"><LockKeyhole size={25}/></div><p className="eyebrow">STAFF PORTAL</p><h1>Sign in securely</h1><p className="lede">Use your organization-issued account. Access is enforced by Supabase Auth and your assigned role.</p><form onSubmit={submit}><label>Work email<input required type="email" autoComplete="username" value={email} onChange={e=>setEmail(e.target.value)} /></label><label>Password<input required type="password" autoComplete="current-password" value={password} onChange={e=>setPassword(e.target.value)} /></label>{error&&<p className="security">{error}</p>}<button className="primary" disabled={busy}>{busy?'Signing in…':'Sign in'} <ShieldCheck size={17}/></button></form><button className="textbtn" onClick={onBack}>Return to public site</button></section>;
}
