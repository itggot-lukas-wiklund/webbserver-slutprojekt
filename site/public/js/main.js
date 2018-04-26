// ----- Like -----
function likeQuestion(element, accountID, questionID) {
    var http = new XMLHttpRequest();
    var questionLikes = document.getElementById("question-likes-" + questionID);
    http.open("POST", "/like_question/", true);
    http.setRequestHeader("Content-type","application/x-www-form-urlencoded");
    http.send("account_id=" + accountID + "&question_id=" + questionID);
    http.onload = function() {
        element.classList.toggle("text-liked");
        var likes = http.responseText;
        questionLikes.innerHTML = likes + " Like";
        if (likes != "1") {
            questionLikes.innerHTML += "s";
        }
    }
}

function likeAnswer(element, accountID, answerID) {
    var http = new XMLHttpRequest();
    var answerLikes = document.getElementById("answer-likes-" + answerID);
    http.open("POST", "/like_answer/", true);
    http.setRequestHeader("Content-type","application/x-www-form-urlencoded");
    http.send("account_id=" + accountID + "&answer_id=" + answerID);
    http.onload = function() {
        element.classList.toggle("text-liked");
        var likes = http.responseText;
        answerLikes.innerHTML = likes + " Like";
        if (likes != "1") {
            answerLikes.innerHTML += "s";
        }
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