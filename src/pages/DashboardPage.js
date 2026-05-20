function DashboardPage() {
  const stats = [
    { titre: 'Écoles', valeur: '12', couleur: 'bg-blue-500' },
    { titre: 'Élèves', valeur: '2 458', couleur: 'bg-green-500' },
    { titre: 'Classes', valeur: '84', couleur: 'bg-purple-500' },
    { titre: 'Bulletins', valeur: '1 230', couleur: 'bg-amber-500' },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900">Tableau de bord</h1>
      <p className="text-gray-500 mt-1">Vue d'ensemble de la plateforme</p>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mt-6">
        {stats.map((stat, index) => (
          <div key={index} className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
            <p className="text-sm text-gray-500">{stat.titre}</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{stat.valeur}</p>
            <div className={`w-12 h-1 ${stat.couleur} rounded-full mt-3`}></div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default DashboardPage;