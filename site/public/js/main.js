// ----- Like and Comment -----
function likeQuestion(element, questionID) {
    var http = new XMLHttpRequest();
    http.open("POST", "/like_question/", true);
    http.setRequestHeader("Content-type","application/x-www-form-urlencoded");
    http.send("question_id=" + questionID);
    http.onload = function() {
        element.classList.toggle("text-liked");
    }
}

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