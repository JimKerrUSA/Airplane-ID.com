import React, { useState } from 'react';

const AircraftIDWireframes = () => {
  const [activeScreen, setActiveScreen] = useState('home');
  
  const screens = [
    { id: 'home', name: 'Home', icon: '🏠' },
    { id: 'camera', name: 'Camera', icon: '📸' },
    { id: 'result', name: 'Result', icon: '✈️' },
    { id: 'hangar', name: 'Hangar', icon: '📒' },
    { id: 'profile', name: 'Profile', icon: '👤' }
  ];

  const Phone = ({ children, title }) => (
    <div className="relative">
      <div className="w-72 h-[580px] bg-slate-900 rounded-[40px] p-2 shadow-2xl">
        <div className="w-full h-full bg-slate-950 rounded-[32px] overflow-hidden relative">
          {/* Status Bar */}
          <div className="absolute top-0 left-0 right-0 h-11 bg-slate-950 z-10 flex items-center justify-between px-6 text-white text-xs">
            <span>9:41</span>
            <div className="w-24 h-7 bg-black rounded-full" />
            <div className="flex gap-1 items-center">
              <span>📶</span>
              <span>🔋</span>
            </div>
          </div>
          {/* Screen Content */}
          <div className="pt-11 h-full overflow-hidden">
            {children}
          </div>
        </div>
      </div>
      <div className="text-center mt-3 text-slate-400 text-sm font-medium">{title}</div>
    </div>
  );

  const TabBar = ({ active }) => (
    <div className="absolute bottom-0 left-0 right-0 h-20 bg-slate-900/95 backdrop-blur border-t border-slate-800 flex justify-around items-center px-2 pb-4">
      {[
        { id: 'home', icon: '🏠', label: 'Home' },
        { id: 'hangar', icon: '✈️', label: 'Hangar' },
        { id: 'camera', icon: '📸', label: 'Scan' },
        { id: 'discover', icon: '🗺️', label: 'Discover' },
        { id: 'profile', icon: '👤', label: 'Profile' }
      ].map(item => (
        <button 
          key={item.id}
          className={`flex flex-col items-center gap-1 ${item.id === 'camera' ? '-mt-8' : ''}`}
        >
          <div className={`${item.id === 'camera' 
            ? 'w-14 h-14 bg-gradient-to-br from-sky-400 to-blue-600 rounded-full flex items-center justify-center text-2xl shadow-lg shadow-sky-500/30' 
            : `w-10 h-10 rounded-xl flex items-center justify-center text-xl ${active === item.id ? 'bg-slate-800' : ''}`}`}>
            {item.icon}
          </div>
          <span className={`text-[10px] ${active === item.id ? 'text-sky-400' : 'text-slate-500'}`}>
            {item.label}
          </span>
        </button>
      ))}
    </div>
  );

  // Home Screen
  const HomeScreen = () => (
    <div className="h-full bg-gradient-to-b from-slate-900 to-slate-950 text-white relative">
      <div className="p-5 pb-24">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-slate-400 text-sm">Good morning</p>
            <h1 className="text-xl font-bold">AvGeek Pro</h1>
          </div>
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center text-lg">
            🔥
          </div>
        </div>

        {/* Stats Card */}
        <div className="bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl p-4 mb-5 border border-slate-700/50">
          <div className="flex justify-between items-center mb-3">
            <span className="text-slate-400 text-sm">Your Spotting Stats</span>
            <span className="text-xs bg-sky-500/20 text-sky-400 px-2 py-1 rounded-full">Level 12</span>
          </div>
          <div className="grid grid-cols-3 gap-3 text-center">
            <div>
              <p className="text-2xl font-bold text-white">247</p>
              <p className="text-[10px] text-slate-500">Aircraft</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-emerald-400">89</p>
              <p className="text-[10px] text-slate-500">Types</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-amber-400">14</p>
              <p className="text-[10px] text-slate-500">Day Streak</p>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="flex gap-3 mb-5">
          <button className="flex-1 bg-sky-500 rounded-xl p-3 flex items-center justify-center gap-2">
            <span>📸</span>
            <span className="text-sm font-medium">Identify Aircraft</span>
          </button>
          <button className="w-12 bg-slate-800 rounded-xl flex items-center justify-center">
            <span>🎓</span>
          </button>
        </div>

        {/* Recent Spottings */}
        <div className="mb-4">
          <div className="flex justify-between items-center mb-3">
            <h2 className="font-semibold">Recent Spottings</h2>
            <span className="text-sky-400 text-sm">See all</span>
          </div>
          <div className="space-y-2">
            {[
              { type: 'Boeing 787-9', airline: 'United', time: '2h ago', img: '🛫' },
              { type: 'Airbus A350-900', airline: 'Qatar', time: 'Yesterday', img: '🛬' },
              { type: 'Embraer E175', airline: 'SkyWest', time: '2 days ago', img: '✈️' }
            ].map((item, i) => (
              <div key={i} className="bg-slate-800/50 rounded-xl p-3 flex items-center gap-3 border border-slate-700/30">
                <div className="w-12 h-12 bg-slate-700 rounded-lg flex items-center justify-center text-xl">
                  {item.img}
                </div>
                <div className="flex-1">
                  <p className="font-medium text-sm">{item.type}</p>
                  <p className="text-slate-500 text-xs">{item.airline} • {item.time}</p>
                </div>
                <span className="text-slate-600">›</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <TabBar active="home" />
    </div>
  );

  // Camera Screen
  const CameraScreen = () => (
    <div className="h-full bg-black text-white relative">
      {/* Camera Viewfinder */}
      <div className="absolute inset-0 bg-gradient-to-b from-slate-900/50 via-transparent to-slate-900/80">
        {/* Simulated aircraft in frame */}
        <div className="absolute top-1/3 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
          <div className="text-6xl opacity-60">✈️</div>
        </div>
        
        {/* Scanning Frame */}
        <div className="absolute top-1/4 left-1/2 transform -translate-x-1/2 w-56 h-40">
          <div className="absolute top-0 left-0 w-8 h-8 border-t-2 border-l-2 border-sky-400 rounded-tl-lg" />
          <div className="absolute top-0 right-0 w-8 h-8 border-t-2 border-r-2 border-sky-400 rounded-tr-lg" />
          <div className="absolute bottom-0 left-0 w-8 h-8 border-b-2 border-l-2 border-sky-400 rounded-bl-lg" />
          <div className="absolute bottom-0 right-0 w-8 h-8 border-b-2 border-r-2 border-sky-400 rounded-br-lg" />
          
          {/* Scanning line animation */}
          <div className="absolute top-1/2 left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-sky-400 to-transparent animate-pulse" />
        </div>
      </div>

      {/* Top Bar */}
      <div className="absolute top-12 left-0 right-0 px-5 flex justify-between items-center">
        <button className="w-10 h-10 bg-black/50 rounded-full flex items-center justify-center backdrop-blur">
          ✕
        </button>
        <div className="bg-black/50 backdrop-blur rounded-full px-4 py-2 flex items-center gap-2">
          <div className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse" />
          <span className="text-sm">AI Ready</span>
        </div>
        <button className="w-10 h-10 bg-black/50 rounded-full flex items-center justify-center backdrop-blur">
          ⚡
        </button>
      </div>

      {/* Instructions */}
      <div className="absolute top-40 left-0 right-0 text-center">
        <p className="text-slate-300 text-sm">Point camera at aircraft</p>
      </div>

      {/* Bottom Controls */}
      <div className="absolute bottom-0 left-0 right-0 bg-black/80 backdrop-blur-xl pt-6 pb-10 rounded-t-3xl">
        <div className="flex items-center justify-center gap-8">
          {/* Gallery */}
          <button className="w-12 h-12 rounded-xl bg-slate-800 flex items-center justify-center overflow-hidden border border-slate-700">
            <span className="text-2xl">🖼️</span>
          </button>
          
          {/* Shutter */}
          <button className="w-20 h-20 rounded-full bg-white flex items-center justify-center shadow-lg">
            <div className="w-16 h-16 rounded-full bg-white border-4 border-slate-200" />
          </button>
          
          {/* Mode Switch */}
          <button className="w-12 h-12 rounded-xl bg-slate-800 flex items-center justify-center border border-slate-700">
            <span className="text-xl">🔄</span>
          </button>
        </div>
        
        {/* Mode Selector */}
        <div className="flex justify-center gap-6 mt-4 text-sm">
          <span className="text-slate-500">Video</span>
          <span className="text-sky-400 font-medium">Photo</span>
          <span className="text-slate-500">Burst</span>
        </div>
      </div>
    </div>
  );

  // Result Screen
  const ResultScreen = () => (
    <div className="h-full bg-slate-950 text-white relative overflow-y-auto pb-24">
      {/* Hero Image */}
      <div className="h-48 bg-gradient-to-br from-sky-900 to-slate-800 relative">
        <div className="absolute inset-0 flex items-center justify-center text-7xl opacity-50">
          ✈️
        </div>
        <div className="absolute top-4 left-4">
          <button className="w-10 h-10 bg-black/30 backdrop-blur rounded-full flex items-center justify-center">
            ←
          </button>
        </div>
        <div className="absolute top-4 right-4 flex gap-2">
          <button className="w-10 h-10 bg-black/30 backdrop-blur rounded-full flex items-center justify-center">
            ♡
          </button>
          <button className="w-10 h-10 bg-black/30 backdrop-blur rounded-full flex items-center justify-center">
            ↗
          </button>
        </div>
        
        {/* Confidence Badge */}
        <div className="absolute bottom-4 right-4 bg-emerald-500/90 backdrop-blur px-3 py-1.5 rounded-full flex items-center gap-1.5">
          <span className="text-xs font-bold">98%</span>
          <span className="text-xs">match</span>
        </div>
      </div>

      {/* Content */}
      <div className="p-5 -mt-6 relative">
        {/* Main Card */}
        <div className="bg-slate-900 rounded-2xl p-5 border border-slate-800 mb-4">
          <div className="flex items-start justify-between mb-2">
            <div>
              <h1 className="text-2xl font-bold">Boeing 787-9</h1>
              <p className="text-sky-400">Dreamliner</p>
            </div>
            <div className="bg-slate-800 px-3 py-1 rounded-lg">
              <span className="text-xs text-slate-400">Wide-body</span>
            </div>
          </div>
          
          <div className="flex items-center gap-2 mt-3">
            <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center font-bold text-xs">
              UA
            </div>
            <span className="text-slate-300">United Airlines Livery</span>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-3 mb-4">
          {[
            { label: 'Passengers', value: '296', icon: '👥' },
            { label: 'Range', value: '14,140 km', icon: '📏' },
            { label: 'First Flight', value: '2009', icon: '📅' }
          ].map((stat, i) => (
            <div key={i} className="bg-slate-900 rounded-xl p-3 text-center border border-slate-800">
              <span className="text-lg">{stat.icon}</span>
              <p className="text-sm font-bold mt-1">{stat.value}</p>
              <p className="text-[10px] text-slate-500">{stat.label}</p>
            </div>
          ))}
        </div>

        {/* Details */}
        <div className="bg-slate-900 rounded-2xl p-4 border border-slate-800 mb-4">
          <h3 className="font-semibold mb-3">Specifications</h3>
          <div className="space-y-2 text-sm">
            {[
              { label: 'Manufacturer', value: 'Boeing' },
              { label: 'Engines', value: '2× GEnx-1B or RR Trent 1000' },
              { label: 'Wingspan', value: '60.1 m (197 ft)' },
              { label: 'Length', value: '62.8 m (206 ft)' },
              { label: 'Cruise Speed', value: 'Mach 0.85' }
            ].map((item, i) => (
              <div key={i} className="flex justify-between">
                <span className="text-slate-500">{item.label}</span>
                <span className="text-slate-300">{item.value}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-3">
          <button className="flex-1 bg-sky-500 rounded-xl py-3 font-medium">
            Add to Hangar
          </button>
          <button className="w-12 bg-slate-800 rounded-xl flex items-center justify-center">
            📤
          </button>
        </div>
      </div>
    </div>
  );

  // Hangar/Collection Screen
  const HangarScreen = () => (
    <div className="h-full bg-slate-950 text-white relative pb-24">
      <div className="p-5">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold">My Hangar</h1>
          <div className="flex gap-2">
            <button className="w-10 h-10 bg-slate-800 rounded-xl flex items-center justify-center">
              🔍
            </button>
            <button className="w-10 h-10 bg-slate-800 rounded-xl flex items-center justify-center">
              ☰
            </button>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2 mb-5 overflow-x-auto pb-2">
          {['All', 'Boeing', 'Airbus', 'Military', 'GA'].map((tab, i) => (
            <button 
              key={tab}
              className={`px-4 py-2 rounded-full text-sm whitespace-nowrap ${i === 0 ? 'bg-sky-500' : 'bg-slate-800 text-slate-400'}`}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* Collection Stats */}
        <div className="bg-gradient-to-r from-sky-900/50 to-blue-900/50 rounded-2xl p-4 mb-5 border border-sky-800/30">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-sky-300 text-sm">Collection Progress</p>
              <p className="text-2xl font-bold">89 / 500</p>
            </div>
            <div className="text-right">
              <p className="text-slate-400 text-sm">17.8% Complete</p>
              <div className="w-24 h-2 bg-slate-700 rounded-full mt-1">
                <div className="w-[18%] h-full bg-sky-400 rounded-full" />
              </div>
            </div>
          </div>
        </div>

        {/* Aircraft Grid */}
        <div className="grid grid-cols-2 gap-3">
          {[
            { name: 'Boeing 787-9', airline: 'United', count: 12, badge: '🏆' },
            { name: 'Airbus A350-900', airline: 'Qatar', count: 8, badge: null },
            { name: 'Boeing 737 MAX 9', airline: 'Alaska', count: 5, badge: '🆕' },
            { name: 'Embraer E175', airline: 'SkyWest', count: 15, badge: null },
            { name: 'F-22 Raptor', airline: 'USAF', count: 1, badge: '⭐' },
            { name: 'Cessna 172', airline: 'Private', count: 3, badge: null }
          ].map((aircraft, i) => (
            <div key={i} className="bg-slate-900 rounded-2xl p-3 border border-slate-800 relative">
              {aircraft.badge && (
                <span className="absolute top-2 right-2">{aircraft.badge}</span>
              )}
              <div className="w-full h-16 bg-slate-800 rounded-lg mb-2 flex items-center justify-center text-2xl">
                ✈️
              </div>
              <p className="font-medium text-sm truncate">{aircraft.name}</p>
              <p className="text-slate-500 text-xs">{aircraft.airline}</p>
              <div className="flex items-center gap-1 mt-2">
                <div className="w-5 h-5 bg-slate-800 rounded flex items-center justify-center text-[10px]">
                  📸
                </div>
                <span className="text-xs text-slate-400">×{aircraft.count}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
      <TabBar active="hangar" />
    </div>
  );

  // Profile Screen
  const ProfileScreen = () => (
    <div className="h-full bg-slate-950 text-white relative pb-24">
      <div className="p-5">
        {/* Profile Header */}
        <div className="flex items-center gap-4 mb-6">
          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-sky-400 to-blue-600 flex items-center justify-center text-3xl">
            👨‍✈️
          </div>
          <div>
            <h1 className="text-xl font-bold">SkyWatcher_247</h1>
            <p className="text-slate-400 text-sm">Aviation Enthusiast</p>
            <div className="flex items-center gap-2 mt-1">
              <span className="bg-amber-500/20 text-amber-400 text-xs px-2 py-0.5 rounded-full">
                Level 12
              </span>
              <span className="text-slate-500 text-xs">2,450 XP</span>
            </div>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-4 gap-2 mb-6">
          {[
            { value: '247', label: 'Spotted' },
            { value: '89', label: 'Types' },
            { value: '14', label: 'Streak' },
            { value: '23', label: 'Badges' }
          ].map((stat, i) => (
            <div key={i} className="bg-slate-900 rounded-xl p-3 text-center border border-slate-800">
              <p className="text-lg font-bold">{stat.value}</p>
              <p className="text-[10px] text-slate-500">{stat.label}</p>
            </div>
          ))}
        </div>

        {/* Achievements */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-3">
            <h2 className="font-semibold">Recent Achievements</h2>
            <span className="text-sky-400 text-sm">See all</span>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-2">
            {[
              { icon: '🛫', name: 'First Flight', color: 'from-emerald-500 to-emerald-700' },
              { icon: '💯', name: '100 Spotted', color: 'from-blue-500 to-blue-700' },
              { icon: '🎖️', name: 'Military Pro', color: 'from-amber-500 to-amber-700' },
              { icon: '🌙', name: 'Night Owl', color: 'from-purple-500 to-purple-700' }
            ].map((badge, i) => (
              <div key={i} className={`w-20 flex-shrink-0 bg-gradient-to-br ${badge.color} rounded-xl p-3 text-center`}>
                <span className="text-2xl">{badge.icon}</span>
                <p className="text-[10px] mt-1 font-medium">{badge.name}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Settings Menu */}
        <div className="space-y-2">
          {[
            { icon: '⚙️', label: 'Settings', arrow: true },
            { icon: '📊', label: 'Statistics', arrow: true },
            { icon: '🔔', label: 'Notifications', arrow: true },
            { icon: '⭐', label: 'Rate App', arrow: true },
            { icon: '💬', label: 'Send Feedback', arrow: true }
          ].map((item, i) => (
            <button key={i} className="w-full bg-slate-900 rounded-xl p-4 flex items-center gap-3 border border-slate-800">
              <span>{item.icon}</span>
              <span className="flex-1 text-left text-sm">{item.label}</span>
              {item.arrow && <span className="text-slate-600">›</span>}
            </button>
          ))}
        </div>
      </div>
      <TabBar active="profile" />
    </div>
  );

  const renderScreen = () => {
    switch(activeScreen) {
      case 'home': return <HomeScreen />;
      case 'camera': return <CameraScreen />;
      case 'result': return <ResultScreen />;
      case 'hangar': return <HangarScreen />;
      case 'profile': return <ProfileScreen />;
      default: return <HomeScreen />;
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 py-8 px-4">
      {/* Header */}
      <div className="max-w-6xl mx-auto mb-8">
        <h1 className="text-3xl font-bold text-white text-center mb-2">
          ✈️ Aircraft ID App — Wireframes
        </h1>
        <p className="text-slate-400 text-center mb-6">
          Interactive wireframe mockups for iOS aircraft identification app
        </p>
        
        {/* Screen Selector */}
        <div className="flex flex-wrap justify-center gap-2 mb-8">
          {screens.map(screen => (
            <button
              key={screen.id}
              onClick={() => setActiveScreen(screen.id)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                activeScreen === screen.id 
                  ? 'bg-sky-500 text-white' 
                  : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
              }`}
            >
              {screen.icon} {screen.name}
            </button>
          ))}
        </div>
      </div>

      {/* Phone Preview */}
      <div className="flex justify-center mb-12">
        <Phone title={screens.find(s => s.id === activeScreen)?.name || 'Home'}>
          {renderScreen()}
        </Phone>
      </div>

      {/* All Screens Overview */}
      <div className="max-w-6xl mx-auto">
        <h2 className="text-xl font-bold text-white text-center mb-6">All Screens Overview</h2>
        <div className="flex flex-wrap justify-center gap-6">
          {screens.map(screen => (
            <div key={screen.id} className="transform scale-[0.65] origin-top">
              <Phone title={screen.name}>
                {screen.id === 'home' && <HomeScreen />}
                {screen.id === 'camera' && <CameraScreen />}
                {screen.id === 'result' && <ResultScreen />}
                {screen.id === 'hangar' && <HangarScreen />}
                {screen.id === 'profile' && <ProfileScreen />}
              </Phone>
            </div>
          ))}
        </div>
      </div>

      {/* Feature Notes */}
      <div className="max-w-4xl mx-auto mt-12 bg-slate-900 rounded-2xl p-6 border border-slate-800">
        <h2 className="text-xl font-bold text-white mb-4">Key Design Decisions</h2>
        <div className="grid md:grid-cols-2 gap-4 text-sm">
          <div className="bg-slate-800/50 rounded-xl p-4">
            <h3 className="font-semibold text-sky-400 mb-2">🎯 Professional Aesthetic</h3>
            <p className="text-slate-400">Dark theme appeals to serious aviation enthusiasts. Avoids the cartoonish look competitors use that received negative reviews.</p>
          </div>
          <div className="bg-slate-800/50 rounded-xl p-4">
            <h3 className="font-semibold text-sky-400 mb-2">✅ Confidence Score</h3>
            <p className="text-slate-400">Prominently displays AI confidence percentage to build trust — a direct response to competitor complaints about accuracy.</p>
          </div>
          <div className="bg-slate-800/50 rounded-xl p-4">
            <h3 className="font-semibold text-sky-400 mb-2">🎮 Gamification</h3>
            <p className="text-slate-400">XP, levels, streaks, and achievements encourage daily engagement without feeling childish.</p>
          </div>
          <div className="bg-slate-800/50 rounded-xl p-4">
            <h3 className="font-semibold text-sky-400 mb-2">📸 Camera-First</h3>
            <p className="text-slate-400">Large, centered scan button in tab bar makes the core function always accessible. Clear framing guides in camera view.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AircraftIDWireframes;
