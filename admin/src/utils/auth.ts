const TOKEN_KEY = 'admin_token';
const USERNAME_KEY = 'admin_username';

export const getToken = (): string | null => {
  return localStorage.getItem(TOKEN_KEY);
};

export const setToken = (token: string): void => {
  localStorage.setItem(TOKEN_KEY, token);
};

export const setUsername = (username: string): void => {
  localStorage.setItem(USERNAME_KEY, username);
};

export const getUsername = (): string | null => {
  return localStorage.getItem(USERNAME_KEY);
};

export const isLoggedIn = (): boolean => {
  return !!getToken();
};

export const logout = (): void => {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USERNAME_KEY);
  window.location.href = '/login';
};
