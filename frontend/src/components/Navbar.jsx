import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Navbar = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/" className="navbar-logo">
          Polling App
        </Link>

        <div className="navbar-menu">
          {user ? (
            <>
              <Link to="/" className="navbar-link">
                Polls
              </Link>
              <Link to="/my-polls" className="navbar-link">
                My Polls
              </Link>
              <Link to="/create-poll" className="navbar-link">
                Create Poll
              </Link>
              <div className="navbar-user">
                <span>Hello, {user.username}</span>
                <button onClick={handleLogout} className="btn-logout">
                  Logout
                </button>
              </div>
            </>
          ) : (
            <>
              <Link to="/login" className="navbar-link">
                Login
              </Link>
              <Link to="/signup" className="navbar-link">
                Sign Up
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
