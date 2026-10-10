import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import type { User } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';

type Role = 'admin' | 'manager' | 'citizen';
type Profile = { id: string; role: Role; team_id: string | null; display_name: string | null };
type AuthState = { user: User | null; profile: Profile | null; loading: boolean; signIn: (email: string, password: string) => Promise<string | null>; signOut: () => Promise<void> };
const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null); const [profile, setProfile] = useState<Profile | null>(null); const [loading, setLoading] = useState(true);
  async function loadProfile(nextUser: User | null) { setUser(nextUser); if (nextUser && supabase) { const { data } = await supabase.from('profiles').select('id,role,team_id,display_name').eq('id', nextUser.id).single(); setProfile(data as Profile | null); } else setProfile(null); setLoading(false); }
  useEffect(() => { if (!supabase) { setLoading(false); return; } supabase.auth.getSession().then(({ data }) => loadProfile(data.session?.user ?? null)); const { data } = supabase.auth.onAuthStateChange((_event, session) => { void loadProfile(session?.user ?? null); }); return () => data.subscription.unsubscribe(); }, []);
  const signIn = async (email: string, password: string) => { if (!supabase) return 'Supabase is not configured. Copy .env.example to .env and add your project values.'; const { error } = await supabase.auth.signInWithPassword({ email, password }); return error?.message ?? null; };
  const signOut = async () => { if (supabase) await supabase.auth.signOut(); setUser(null); setProfile(null); };
  return <AuthContext.Provider value={{ user, profile, loading, signIn, signOut }}>{children}</AuthContext.Provider>;
}
export function useAuth() { const value = useContext(AuthContext); if (!value) throw new Error('useAuth must be used inside AuthProvider'); return value; }
