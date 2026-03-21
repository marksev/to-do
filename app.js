/* ═══════════════════════════════════════════════
   CONFIGURATION — paste your Supabase credentials
═══════════════════════════════════════════════ */
const SUPABASE_URL      = 'https://buhpggvthtrhdaueaktd.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1aHBnZ3Z0aHRyaGRhdWVha3RkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwMjYzMjUsImV4cCI6MjA4OTYwMjMyNX0.Gy6ETwFv6FYWA8QqevxkmRF4owZMlZ8tDRYLKhYWoO4';

const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/* ═══════════════════════════════════════════════
   STATE
═══════════════════════════════════════════════ */
let currentUser  = null;
let todos        = [];
let dailyLogs    = {};        // key: `${todoId}_${dateStr}` → true/false
let calYear      = new Date().getFullYear();
let calMonth     = new Date().getMonth();  // 0-indexed

/* ═══════════════════════════════════════════════
   INIT
═══════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', async () => {
  const { data: { session } } = await sb.auth.getSession();
  if (session) await signIn(session.user);
  else showAuthView();

  sb.auth.onAuthStateChange((_event, session) => {
    if (session) signIn(session.user);
    else { currentUser = null; showAuthView(); }
  });

  bindAuthUI();
  bindAppUI();
});

/* ═══════════════════════════════════════════════
   AUTH HELPERS
═══════════════════════════════════════════════ */
function showAuthView() {
  document.getElementById('auth-view').classList.remove('hidden');
  document.getElementById('app-view').classList.add('hidden');
}
function showAppView() {
  document.getElementById('auth-view').classList.add('hidden');
  document.getElementById('app-view').classList.remove('hidden');
}

async function signIn(user) {
  currentUser = user;
  showAppView();
  await loadTodos();
  showView('today');
}

function bindAuthUI() {
  // Tab switching
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const tab = btn.dataset.tab;
      document.getElementById('login-form').classList.toggle('hidden', tab !== 'login');
      document.getElementById('signup-form').classList.toggle('hidden', tab !== 'signup');
      clearAuthErrors();
    });
  });

  // Login
  document.getElementById('login-form').addEventListener('submit', async e => {
    e.preventDefault();
    clearAuthErrors();
    const email    = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    const btn = e.target.querySelector('.btn-primary');
    btn.disabled = true; btn.textContent = 'Logging in…';
    const { error } = await sb.auth.signInWithPassword({ email, password });
    btn.disabled = false; btn.textContent = 'Login';
    if (error) document.getElementById('login-error').textContent = error.message;
  });

  // Signup
  document.getElementById('signup-form').addEventListener('submit', async e => {
    e.preventDefault();
    clearAuthErrors();
    const email    = document.getElementById('signup-email').value.trim();
    const password = document.getElementById('signup-password').value;
    const btn = e.target.querySelector('.btn-primary');
    btn.disabled = true; btn.textContent = 'Creating account…';
    const { error } = await sb.auth.signUp({ email, password });
    btn.disabled = false; btn.textContent = 'Create Account';
    if (error) {
      document.getElementById('signup-error').textContent = error.message;
    } else {
      document.getElementById('signup-success').textContent =
        'Account created! Check your email to confirm, then log in.';
    }
  });

  // Logout
  document.getElementById('logout-btn').addEventListener('click', async () => {
    await sb.auth.signOut();
  });
}

function clearAuthErrors() {
  ['login-error','signup-error','signup-success'].forEach(id => {
    document.getElementById(id).textContent = '';
  });
}

/* ═══════════════════════════════════════════════
   VIEW SWITCHING
═══════════════════════════════════════════════ */
function bindAppUI() {
  document.querySelectorAll('.nav-btn[data-view]').forEach(btn => {
    btn.addEventListener('click', () => {
      showView(btn.dataset.view);
    });
  });
  document.getElementById('cal-prev').addEventListener('click', () => {
    calMonth--; if (calMonth < 0) { calMonth = 11; calYear--; }
    renderCalendar();
  });
  document.getElementById('cal-next').addEventListener('click', () => {
    calMonth++; if (calMonth > 11) { calMonth = 0; calYear++; }
    renderCalendar();
  });
  document.getElementById('add-todo-form').addEventListener('submit', handleAddTodo);
}

function showView(name) {
  ['today','calendar','manage'].forEach(v => {
    document.getElementById(`${v}-view`).classList.toggle('hidden', v !== name);
  });
  document.querySelectorAll('.nav-btn[data-view]').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.view === name);
  });
  if (name === 'today')    renderToday();
  if (name === 'calendar') { renderCalendar(); }
  if (name === 'manage')   renderManage();
}

/* ═══════════════════════════════════════════════
   TODOS — CRUD
═══════════════════════════════════════════════ */
async function loadTodos() {
  const { data, error } = await sb
    .from('todos')
    .select('*')
    .eq('user_id', currentUser.id)
    .order('created_at', { ascending: true });
  if (error) { console.error(error); return; }
  todos = data || [];
}

async function handleAddTodo(e) {
  e.preventDefault();
  const input = document.getElementById('new-todo-input');
  const title = input.value.trim();
  if (!title) return;

  const { data, error } = await sb
    .from('todos')
    .insert({ user_id: currentUser.id, title })
    .select()
    .single();
  if (error) { console.error(error); return; }
  todos.push(data);
  input.value = '';
  renderManage();
}

async function deleteTodo(id) {
  const { error } = await sb.from('todos').delete().eq('id', id);
  if (error) { console.error(error); return; }
  todos = todos.filter(t => t.id !== id);
  renderManage();
}

/* ═══════════════════════════════════════════════
   DAILY LOGS
═══════════════════════════════════════════════ */
function todayStr() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

function logKey(todoId, dateStr) {
  return `${todoId}_${dateStr}`;
}

async function loadLogsForMonth(year, month) {
  const firstDay = `${year}-${String(month + 1).padStart(2,'0')}-01`;
  const lastDay  = new Date(year, month + 1, 0).toISOString().slice(0, 10);

  const { data, error } = await sb
    .from('daily_logs')
    .select('*')
    .eq('user_id', currentUser.id)
    .gte('date', firstDay)
    .lte('date', lastDay);

  if (error) { console.error(error); return; }
  (data || []).forEach(row => {
    dailyLogs[logKey(row.todo_id, row.date)] = row.completed;
  });
}

async function loadTodayLogs() {
  const today = todayStr();
  const { data, error } = await sb
    .from('daily_logs')
    .select('*')
    .eq('user_id', currentUser.id)
    .eq('date', today);
  if (error) { console.error(error); return; }
  (data || []).forEach(row => {
    dailyLogs[logKey(row.todo_id, row.date)] = row.completed;
  });
}

async function setLog(todoId, dateStr, completed) {
  const key = logKey(todoId, dateStr);
  dailyLogs[key] = completed;

  const { error } = await sb.from('daily_logs').upsert(
    { todo_id: todoId, user_id: currentUser.id, date: dateStr, completed },
    { onConflict: 'todo_id,date' }
  );
  if (error) console.error(error);
}

/* ═══════════════════════════════════════════════
   RENDER: TODAY VIEW
═══════════════════════════════════════════════ */
async function renderToday() {
  const today = todayStr();
  await loadTodayLogs();

  // heading
  const now = new Date();
  document.getElementById('today-heading').textContent =
    now.toLocaleDateString('en-US', { weekday: 'long' });
  document.getElementById('today-date').textContent =
    now.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });

  // streak
  const streak = await calcStreak();
  document.getElementById('streak-count').textContent = streak;

  const list  = document.getElementById('todo-list');
  const empty = document.getElementById('today-empty');
  list.innerHTML = '';

  if (todos.length === 0) { empty.classList.remove('hidden'); return; }
  empty.classList.add('hidden');

  todos.forEach(todo => {
    const key = logKey(todo.id, today);
    const val = dailyLogs[key]; // true | false | undefined

    const card = document.createElement('div');
    card.className = 'todo-card' +
      (val === true ? ' logged-yes' : val === false ? ' logged-no' : '');
    card.innerHTML = `
      <span class="todo-status-dot ${val === true ? 'yes' : val === false ? 'no' : ''}"></span>
      <span class="todo-title">${escHtml(todo.title)}</span>
      <div class="yn-buttons">
        <button class="yn-btn yes ${val === true ? 'active' : ''}">YES</button>
        <button class="yn-btn no  ${val === false ? 'active' : ''}">NO</button>
      </div>
    `;

    const yesBtn = card.querySelector('.yn-btn.yes');
    const noBtn  = card.querySelector('.yn-btn.no');

    yesBtn.addEventListener('click', async () => {
      await setLog(todo.id, today, true);
      renderToday();
    });
    noBtn.addEventListener('click', async () => {
      await setLog(todo.id, today, false);
      renderToday();
    });

    list.appendChild(card);
  });
}

/* ═══════════════════════════════════════════════
   RENDER: CALENDAR VIEW (habit-tracker grid)
═══════════════════════════════════════════════ */
async function renderCalendar() {
  await loadLogsForMonth(calYear, calMonth);

  const monthNames = ['January','February','March','April','May','June',
                      'July','August','September','October','November','December'];
  document.getElementById('cal-month-label').textContent =
    `${monthNames[calMonth]} ${calYear}`;

  const daysInMonth = new Date(calYear, calMonth + 1, 0).getDate();
  const todayFull   = new Date();
  const todayDateStr = todayStr();

  const container = document.getElementById('calendar-container');

  if (todos.length === 0) {
    container.innerHTML = '<p class="empty-state">No tasks to display.</p>';
    return;
  }

  // Build table
  let html = '<table class="cal-table"><thead><tr>';
  html += '<th></th>'; // todo label column

  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${calYear}-${String(calMonth+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
    const isToday = dateStr === todayDateStr;
    const dow = new Date(calYear, calMonth, d)
      .toLocaleDateString('en-US', { weekday: 'short' }).slice(0,2);
    html += `<th class="${isToday ? 'today-col' : ''}">${d}<br/><small>${dow}</small></th>`;
  }
  html += '</tr></thead><tbody>';

  todos.forEach(todo => {
    html += `<tr><td class="cal-row-label" title="${escHtml(todo.title)}">${escHtml(todo.title)}</td>`;

    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${calYear}-${String(calMonth+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
      const isFuture = dateStr > todayDateStr;
      const isToday  = dateStr === todayDateStr;
      const val      = dailyLogs[logKey(todo.id, dateStr)];

      let cls = 'none';
      if (isFuture)        cls = 'future';
      else if (val === true)  cls = 'yes';
      else if (val === false) cls = 'no';

      const todayCls = isToday ? ' today-dot' : '';
      const title    = isFuture ? '' : (val === true ? 'Yes ✓' : val === false ? 'No ✗' : 'Not logged');

      html += `<td class="cal-cell"><span class="cal-dot ${cls}${todayCls}" title="${title}"></span></td>`;
    }
    html += '</tr>';
  });

  html += '</tbody></table>';
  container.innerHTML = html;
}

/* ═══════════════════════════════════════════════
   RENDER: MANAGE VIEW
═══════════════════════════════════════════════ */
function renderManage() {
  const list  = document.getElementById('manage-list');
  const empty = document.getElementById('manage-empty');
  list.innerHTML = '';

  if (todos.length === 0) { empty.classList.remove('hidden'); return; }
  empty.classList.add('hidden');

  todos.forEach(todo => {
    const li = document.createElement('li');
    li.className = 'manage-item';
    li.innerHTML = `
      <span class="manage-item-title">${escHtml(todo.title)}</span>
      <button class="delete-btn" title="Delete task">✕</button>
    `;
    li.querySelector('.delete-btn').addEventListener('click', () => {
      if (confirm(`Delete "${todo.title}"? This will also remove all its history.`))
        deleteTodo(todo.id);
    });
    list.appendChild(li);
  });
}

/* ═══════════════════════════════════════════════
   STREAK CALCULATOR
   Counts consecutive days where ALL tasks are YES
═══════════════════════════════════════════════ */
async function calcStreak() {
  if (todos.length === 0) return 0;

  // Load last 90 days of logs
  const today = new Date();
  const from  = new Date(today); from.setDate(from.getDate() - 90);
  const fromStr = from.toISOString().slice(0,10);

  const { data } = await sb
    .from('daily_logs')
    .select('*')
    .eq('user_id', currentUser.id)
    .gte('date', fromStr)
    .order('date', { ascending: false });

  if (!data || data.length === 0) return 0;

  // Build a set of "perfect days" (all todos answered YES)
  const byDate = {};
  data.forEach(row => {
    if (!byDate[row.date]) byDate[row.date] = {};
    byDate[row.date][row.todo_id] = row.completed;
  });

  let streak = 0;
  let cursor = new Date(today);
  cursor.setHours(12,0,0,0);

  while (true) {
    const ds = cursor.toISOString().slice(0,10);
    const dayLogs = byDate[ds] || {};
    const allYes  = todos.every(t => dayLogs[t.id] === true);
    if (!allYes) break;
    streak++;
    cursor.setDate(cursor.getDate() - 1);
    if (streak > 90) break;
  }
  return streak;
}

/* ═══════════════════════════════════════════════
   UTILS
═══════════════════════════════════════════════ */
function escHtml(str) {
  return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
            .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}
