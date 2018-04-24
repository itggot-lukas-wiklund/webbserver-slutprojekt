// ----- Dropdown -----
function toggleAccountDropdown() {
    var dropdown = document.getElementById('account-dropdown');
    var closer = document.getElementById('account-dropdown-closer');
    dropdown.classList.toggle('hidden');
    closer.classList.toggle('hidden');
}

function closeDropdownClicked() {
    var dropdown = document.getElementById('account-dropdown');
    var closer = document.getElementById('account-dropdown-closer');
    dropdown.classList.add('hidden');
    closer.classList.add('hidden');
}