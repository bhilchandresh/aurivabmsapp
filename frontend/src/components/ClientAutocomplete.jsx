import { useState, useEffect, useRef } from "react";
import api from "../utils/api";

const ClientAutocomplete = ({ onSelect, selectedClientId }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const wrapperRef = useRef(null);

  // 1. Initial Load: If a client is already selected (edit mode), fetch them specifically
  useEffect(() => {
    if (selectedClientId) {
       const fetchSelected = async () => {
          try {
             const res = await api.get(`/clients`); // Fallback fetch initial list
             const selected = res.data.data.find(c => c._id === selectedClientId);
             if (selected) {
                setSearchTerm(selected.name);
                setResults(res.data.data.slice(0, 5));
             }
          } catch (e) { console.error("Error fetching selected client", e); }
       };
       fetchSelected();
    }
  }, [selectedClientId]);

  // 2. SEARCH LOGIC with Debounce
  useEffect(() => {
    if (searchTerm.trim().length === 0) {
      setResults([]);
      return;
    }

    const delayDebounceFn = setTimeout(async () => {
      setLoading(true);
      try {
        const res = await api.get(`/clients?search=${encodeURIComponent(searchTerm)}`);
        setResults(res.data.data);
      } catch (err) {
        console.error("Client Search Error", err);
      } finally {
        setLoading(false);
      }
    }, 400); // 400ms debounce

    return () => clearTimeout(delayDebounceFn);
  }, [searchTerm]);

  // 3. Close dropdown if clicked outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleSelect = (client) => {
    setSearchTerm(client.name);
    setIsOpen(false);
    onSelect(client); // Send data back to parent
  };

  return (
    <div className="relative w-full" ref={wrapperRef}>
      <div className="relative">
        <span className="absolute left-3 top-2.5 text-gray-400">🔍</span>
        <input
          type="text"
          className="w-full pl-10 pr-4 py-2 border rounded bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
          placeholder="Type to search clients..."
          value={searchTerm}
          onChange={(e) => {
            setSearchTerm(e.target.value);
            setIsOpen(true);
          }}
          onFocus={() => setIsOpen(true)}
        />
        {/* Clear Button */}
        {searchTerm && (
          <button 
            type="button"
            onClick={() => { setSearchTerm(""); onSelect(null); }}
            className="absolute right-3 top-2.5 text-gray-400 hover:text-red-500"
          >
            ✕
          </button>
        )}
      </div>

      {/* DROPDOWN LIST */}
      {isOpen && (
        <div className="absolute z-50 w-full bg-white border border-gray-200 mt-1 rounded shadow-xl max-h-60 overflow-y-auto">
          {loading ? (
            <div className="p-3 text-gray-400 text-sm text-center italic flex items-center justify-center gap-2">
               <div className="w-3 h-3 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
               Searching...
            </div>
          ) : results.length > 0 ? (
            results.map((client) => (
              <div
                key={client._id}
                onClick={() => handleSelect(client)}
                className="p-3 hover:bg-blue-50 cursor-pointer border-b last:border-0 transition"
              >
                <div className="font-bold text-gray-800 text-sm">{client.name}</div>
                <div className="text-xs text-gray-500">{client.email || 'No Email'} • {client.phone || 'No Phone'}</div>
              </div>
            ))
          ) : searchTerm.trim().length > 0 ? (
            <div className="p-3 text-gray-400 text-sm text-center">No clients found</div>
          ) : null}
        </div>
      )}
    </div>
  );
};

export default ClientAutocomplete;