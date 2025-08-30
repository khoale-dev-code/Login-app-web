import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Login from './components/Auth/Login';
import Register from './components/Auth/Register';
import UserDetails from './components/Auth/UserDetails';

function App() {
  const handleFilter = (e) => {
    const value = e.target.value;
    console.log('Search input:', value);  
  };

  return (
    <Router>
      <div>

        <Routes>
          <Route path="/" element={<Login />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/userDetails" element={<UserDetails />} />
         </Routes>
      </div>
    </Router>
  );
}

export default App;