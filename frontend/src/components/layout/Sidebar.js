import { NavLink } from 'react-router-dom';

function Sidebar() {
  const menuItems = [
    { path: '/dashboard', label: 'Tableau de bord' },
    { path: '/ecoles', label: 'Écoles' },
    { path: '/classes', label: 'Classes' },
    { path: '/eleves', label: 'Élèves' },
    { path: '/notes', label: 'Notes' },
    { path: '/bulletins', label: 'Bulletins' },
    { path: '/utilisateurs', label: 'Utilisateurs' },
  ];

  return (
    <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
      <div className="h-16 flex items-center px-6 border-b border-gray-200">
        <span className="text-lg font-bold text-gray-900">Skula</span>
      </div>

      <nav className="flex-1 px-3 py-4 space-y-1">
        {menuItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `block px-3 py-2 rounded-lg text-sm font-medium ${
                isActive
                  ? 'bg-blue-50 text-blue-700'
                  : 'text-gray-600 hover:bg-gray-50'
              }`
            }
          >
            {item.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}

export default Sidebar;