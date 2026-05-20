function Header() {
  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6">
      <div>
        <input
          type="text"
          placeholder="Rechercher..."
          className="px-4 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <div className="flex items-center gap-3">
        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
          <span className="text-sm font-semibold text-blue-700">AD</span>
        </div>
        <span className="text-sm font-medium text-gray-900">Admin</span>
      </div>
    </header>
  );
}

export default Header;