import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4
import Qt.labs.settings 1.0


Window {
    id: idRoot
    height: 400
    width: 700
    visible: true
    title: qsTr(":: StockManager :: Jônatas G. Alves :: jonatasgomes@gmail.com ::")
    Settings {
        id: idSettings
        property alias x: idRoot.x
        property alias y: idRoot.y
        property alias height: idRoot.height
        property alias width: idRoot.width
        property string stocksArray
    }
    property int pixelSize: 12 * Math.min(height / 400, width / 700)

    function findStocksPrices() {
        if (idSettings.stocksArray.length === 0) {
            return;
        }
        var request = new XMLHttpRequest();
        var url = "http://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quotes where symbol in (" + idSettings.stocksArray + ")&env=http://datatables.org/alltables.env&format=json";
        request.open("GET", url, true);
        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                var jsonObject = JSON.parse(request.responseText);
                if (jsonObject.errors === undefined) {
                    var quotes = jsonObject.query.results.quote;
                    if (quotes.constructor === Array) {
                        for (var index in quotes)
                        {
                            for (var i = 0; i < idStockList.model.count;) {
                                if (idStockList.model.get(i).t + ".SA" === quotes[index].Symbol) {
                                    idStockList.model.setProperty(i, "l", parseFloat(quotes[index].Bid));
                                    idStockList.model.setProperty(i, "a", parseFloat(quotes[index].Open));
                                    idStockList.model.setProperty(i, "n", parseFloat(quotes[index].DaysLow));
                                    idStockList.model.setProperty(i, "x", parseFloat(quotes[index].DaysHigh));
                                }
                                i++;
                            }
                        }
                    } else {
                        idStockList.model.setProperty(0, "l", parseFloat(quotes.Bid));
                        idStockList.model.setProperty(0, "a", parseFloat(quotes.Open));
                        idStockList.model.setProperty(0, "n", parseFloat(quotes.DaysLow));
                        idStockList.model.setProperty(0, "x", parseFloat(quotes.DaysHigh));
                    }
                } else {
                    console.log("Erro: " + jsonObject.errors[0].message);
                    return;
                }
            }
        }
        request.send();
    }

    function copyModel2Array() {
        var stocks = "";
        for (var i = 0; i < idStockList.model.count;) {
            stocks = stocks.concat((i > 0 ? "," : "") + '"' + idStockList.model.get(i).t + '.SA"');
            i++;
        }
        idSettings.stocksArray = stocks;
    }

    function addStockToModel(stock) {
        if (stock.length > 0) {
            for (var i = 0; i < idStockList.count;) {
                if (idStockList.model.get(i).t === stock) {
                    return;
                }
                i++;
            }
            idTimer.stop();
            idStockList.model.append({t: stock, l: 0.00, a: 0.00, n: 0.00, x: 0.00 });
            idStockList.currentIndex = idStockList.count - 1;
            idStockList.positionViewAtEnd();
            copyModel2Array();
            findStocksPrices();
            idTimer.start();
        }
    }

    function removeStockFromModel(p_index) {
        idTimer.stop();
        idStockList.model.remove(p_index);
        copyModel2Array();
        idTimer.start()
        findStocksPrices();
    }

    Component.onCompleted: {
        console.log(idSettings.stocksArray);
        if (idSettings.stocksArray.length > 0) {
            var stocks = idSettings.stocksArray.replace(/"/g, '').split(",");
            for (var i = 0; i < stocks.length;) {
                idStockList.model.append({ t: stocks[i].replace('.SA', ''), l: 0.00, a: 0.00, n: 0.00, x: 0.00 });
                i++;
            }
        }
        findStocksPrices();
        idTimer.start();
    }

    Timer {
        id: idTimer
        interval: 5000
        repeat: true
        onTriggered: findStocksPrices()
    }

    Rectangle {//border.width: 1
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right; rightMargin: parent.width * 0.3
            bottom: parent.bottom; bottomMargin: parent.height * 0.88
        }
        clip: true

        TextField {
            id: idTxtStockToAdd
            anchors {
                top: parent.top; topMargin: parent.height * 0.15
                left: parent.left; leftMargin: parent.width * 0.25
                right: parent.right; rightMargin: parent.width * 0.51
                bottom: parent.bottom; bottomMargin: parent.height * 0.15
            }
            horizontalAlignment: TextInput.AlignHCenter
            font.capitalization: Font.AllUppercase
            font.pixelSize: idRoot.pixelSize * 0.8
            placeholderText: qsTr("ação")
            focus: true
            onAccepted: {
                addStockToModel(idTxtStockToAdd.text.trim().toUpperCase());
                idTxtStockToAdd.text = "";
            }
        }

        Button {
            id: idBtnAddStock
            anchors {
                top: parent.top; topMargin: parent.height * 0.15
                left: parent.left; leftMargin: parent.width * 0.51
                right: parent.right; rightMargin: parent.width * 0.25
                bottom: parent.bottom; bottomMargin: parent.height * 0.15
            }
            style: ButtonStyle {
                label: Text {
                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                    clip: true
                    font.pixelSize: idRoot.pixelSize * 0.8
                    text: control.text
                }
            }
            text: qsTr("Adicionar")
            onClicked: {
                addStockToModel(idTxtStockToAdd.text.trim().toUpperCase());
                idTxtStockToAdd.focus = true;
                idTxtStockToAdd.text = "";
            }
        }

    }

    Rectangle {//border.width: 1
        anchors {
            top: parent.top; topMargin: parent.height * 0.12
            left: parent.left
            right: parent.right; rightMargin: parent.width * 0.3
            bottom: parent.bottom
        }
        clip: true

        ListView {
            id: idStockList
            anchors {
                top: parent.top; topMargin: parent.height * 0.01
                left: parent.left; leftMargin: 1
                right: parent.right; rightMargin: 1
                bottom: parent.bottom; bottomMargin: parent.height * 0.01
            }
            clip: true
            model: ListModel { }
            delegate: Rectangle {
                height: idStockList.height / 10
                width: idStockList.width
                color: ListView.isCurrentItem ? "darkCyan" : "white"
                property bool isSelected: ListView.isCurrentItem
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        idStockList.currentIndex = model.index;
                    }
                }
                Rectangle {//border.width: 1
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right; rightMargin: idStockList.width * 0.2
                        bottom: parent.bottom
                    }
                    color: "transparent"
                    Text {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right; rightMargin: parent.width * 0.75
                            bottom: parent.bottom
                        }
                        verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                        color: model.a > model.l ? "red" : (isSelected ? Qt.lighter("green", 1.9) : "green")
                        font.bold: parent.ListView.isCurrentItem
                        font.pixelSize: idRoot.pixelSize
                        text: model.t + ": " + model.l
                    }
                    Text {
                        anchors {
                            top: parent.top
                            left: parent.left; leftMargin: parent.width * 0.25
                            right: parent.right; rightMargin: parent.width * 0.5
                            bottom: parent.bottom
                        }
                        verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                        color: isSelected ? "white" : "black"
                        font.bold: parent.ListView.isCurrentItem
                        font.pixelSize: idRoot.pixelSize
                        text: "Abertura: " + model.a
                    }
                    Text {
                        anchors {
                            top: parent.top
                            left: parent.left; leftMargin: parent.width * 0.5
                            right: parent.right; rightMargin: parent.width * 0.25
                            bottom: parent.bottom
                        }
                        verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                        color: isSelected ? "white" : "black"
                        font.bold: parent.ListView.isCurrentItem
                        font.pixelSize: idRoot.pixelSize
                        text: "Min: " + model.n
                    }
                    Text {
                        anchors {
                            top: parent.top
                            left: parent.left; leftMargin: parent.width * 0.75
                            right: parent.right
                            bottom: parent.bottom
                        }
                        verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                        color: isSelected ? "white" : "black"
                        font.bold: parent.ListView.isCurrentItem
                        font.pixelSize: idRoot.pixelSize
                        text: "Max: " + model.x
                    }
                }
                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left; leftMargin: idStockList.width * 0.8
                        right: parent.right
                        bottom: parent.bottom
                    }
                    color: "red"
                    visible: parent.ListView.isCurrentItem
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        font.bold: true
                        font.pixelSize: idRoot.pixelSize
                        text: qsTr("Excluir")
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            removeStockFromModel(model.index);
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors {
                top: parent.top; topMargin: - parent.height * 0.01
                left: parent.left; leftMargin: parent.width * 0.01
                right: parent.right; rightMargin: parent.width * 0.01
                bottom: parent.bottom; bottomMargin: parent.height * 0.99
            }
            radius: height * 0.4
            color: "green"
            opacity: 0.3
            visible: !idStockList.atYBeginning
        }

        Rectangle {
            anchors {
                top: parent.top; topMargin: parent.height * 0.99
                left: parent.left; leftMargin: parent.width * 0.01
                right: parent.right; rightMargin: parent.width * 0.01
                bottom: parent.bottom; bottomMargin: - parent.height * 0.01
            }
            radius: height * 0.4
            color: "green"
            opacity: 0.3
            visible: !idStockList.atYEnd
        }

    }

    Rectangle {//border.width: 1
        anchors {
            top: parent.top
            left: parent.left; leftMargin: parent.width * 0.7
            right: parent.right
            bottom: parent.bottom
        }
        clip: true

        ListView {
            id: idAllStocksList
            anchors { fill: parent; margins: 1 }
            model: ListModel {
                ListElement { n: "Banco do Brasil SA"; t: "BBAS3" }
                ListElement { n: "Metalurgica Gerdau S.A. PN"; t: "GOAU4" }
                ListElement { n: "Metalurgica Gerdau S.A. ON"; t: "GOAU3" }
                ListElement { n: "Petroleo Brasileiro SA PN"; t: "PETR4" }
                ListElement { n: "Petroleo Brasileiro SA ON"; t: "PETR3" }
                ListElement { n: "Vale SA PN"; t: "VALE5" }
                ListElement { n: "Vale SA"; t: "VALE3" }
                ListElement { n: "Usiminas PN"; t: "USIM5" }
                ListElement { n: "Usiminas ON"; t: "USIM3" }
            }
            clip: true
            delegate: Rectangle {
                height: idAllStocksList.height / 11
                width: idAllStocksList.width
                color: ListView.isCurrentItem ? "darkCyan" : "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        idAllStocksList.currentIndex = model.index;
                    }
                    onDoubleClicked: {
                        addStockToModel(model.t.trim().toUpperCase());
                    }
                }
                Text {
                    anchors {
                        top: parent.top
                        left: parent.left; leftMargin: idAllStocksList.width * 0.02
                        right: parent.right; rightMargin: idAllStocksList.width * 0.02
                        bottom: parent.bottom
                    }
                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignLeft
                    color: parent.ListView.isCurrentItem ? "white" : "black"
                    font.bold: parent.ListView.isCurrentItem
                    font.pixelSize: idRoot.pixelSize * 0.8
                    text: model.n + " (" + model.t + ")"
                }
            }
        }

    }

}

