/**
 * Returns the current date as a string in YYYY-MM-DD format based on local time.
 */
export const getLocalDateString = () => {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
};

/**
 * Returns a future/past date as a string in YYYY-MM-DD format based on local time.
 * @param {number} daysOffset 
 */
export const getLocalDateStringWithOffset = (daysOffset) => {
    const target = new Date();
    target.setDate(target.getDate() + daysOffset);
    const yyyy = target.getFullYear();
    const mm = String(target.getMonth() + 1).padStart(2, '0');
    const dd = String(target.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
};
