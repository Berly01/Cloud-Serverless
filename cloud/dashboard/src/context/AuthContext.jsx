import { createContext, useContext, useState, useEffect } from 'react';
import {
  CognitoUserPool,
  CognitoUser,
  AuthenticationDetails,
} from 'amazon-cognito-identity-js';
import { loadConfig } from '../config';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [userPool, setUserPool] = useState(null);
  const [error, setError] = useState(null);

  // Initialize Cognito on mount
  useEffect(() => {
    async function initAuth() {
      try {
        const config = await loadConfig();
        
        if (config.cognitoUserPoolId && config.cognitoClientId) {
          const pool = new CognitoUserPool({
            UserPoolId: config.cognitoUserPoolId,
            ClientId: config.cognitoClientId,
          });
          setUserPool(pool);

          // Check for existing session
          const currentUser = pool.getCurrentUser();
          if (currentUser) {
            currentUser.getSession((err, session) => {
              if (err) {
                console.error('Session error:', err);
                setLoading(false);
                return;
              }
              if (session.isValid()) {
                getUserAttributes(currentUser, session);
              } else {
                setLoading(false);
              }
            });
          } else {
            setLoading(false);
          }
        } else {
          setLoading(false);
        }
      } catch (err) {
        console.error('Auth init error:', err);
        setLoading(false);
      }
    }

    initAuth();
  }, []);

  function getUserAttributes(cognitoUser, session) {
    cognitoUser.getUserAttributes((err, attributes) => {
      if (err) {
        console.error('Error getting user attributes:', err);
        setLoading(false);
        return;
      }

      const userData = {
        username: cognitoUser.getUsername(),
        email: '',
        name: '',
        role: 'patient',
        tokens: {
          idToken: session.getIdToken().getJwtToken(),
          accessToken: session.getAccessToken().getJwtToken(),
          refreshToken: session.getRefreshToken().getToken(),
        },
      };

      attributes.forEach((attr) => {
        if (attr.Name === 'email') userData.email = attr.Value;
        if (attr.Name === 'name') userData.name = attr.Value;
        if (attr.Name === 'custom:role') userData.role = attr.Value;
      });

      // Get groups from ID token
      const idTokenPayload = session.getIdToken().decodePayload();
      userData.groups = idTokenPayload['cognito:groups'] || [];

      setUser(userData);
      setLoading(false);
    });
  }

  async function login(email, password) {
    if (!userPool) {
      throw new Error('Auth not initialized');
    }

    setError(null);

    return new Promise((resolve, reject) => {
      const cognitoUser = new CognitoUser({
        Username: email,
        Pool: userPool,
      });

      const authDetails = new AuthenticationDetails({
        Username: email,
        Password: password,
      });

      cognitoUser.authenticateUser(authDetails, {
        onSuccess: (session) => {
          getUserAttributes(cognitoUser, session);
          resolve(session);
        },
        onFailure: (err) => {
          setError(err.message || 'Error de autenticación');
          reject(err);
        },
        newPasswordRequired: (userAttributes) => {
          // Handle new password required (first login)
          reject({ code: 'NewPasswordRequired', userAttributes });
        },
      });
    });
  }

  function logout() {
    if (userPool) {
      const currentUser = userPool.getCurrentUser();
      if (currentUser) {
        currentUser.signOut();
      }
    }
    setUser(null);
  }

  function getToken() {
    return user?.tokens?.idToken || null;
  }

  const value = {
    user,
    loading,
    error,
    isAuthenticated: !!user,
    login,
    logout,
    getToken,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
