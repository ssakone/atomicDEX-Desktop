import QtQuick 2.14
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import "../Components"
import "../Constants"

DefaultModal {
    id: root

    readonly property bool positive_claim_amount: parseFloat(prepare_claim_rewards_result.withdraw_answer.my_balance_change) > 0
    readonly property bool has_eligible_utxo: {
        const utxos = prepare_claim_rewards_result.kmd_rewards_info.result
        if(!utxos) return false

        for(let i = 0; i < utxos.length; ++i)
            if(!utxos[i].accrued_rewards.NotAccruedReason)
                return true

        return false
    }
    readonly property bool can_confirm: positive_claim_amount && has_eligible_utxo && !is_broadcast_busy
    readonly property bool is_broadcast_busy: API.get().wallet_pg.is_broadcast_busy

    readonly property var default_prepare_claim_rewards_result: ({
         "kmd_rewards_info": {
             "result": [
                 {
                     "accrue_start_at": 1596785618,
                     "accrue_stop_at": 1599460418,
                     "accrue_start_at_human_date": "7 Aug 2020, 08:33",
                     "accrue_stop_at_human_date": "7 Sep 2020, 08:33",
                     "accrued_rewards": {
                         "Accrued": "0"
                     },
                     "amount": "0",
                     "output_index": 0
                 }
             ]
         },
         "withdraw_answer": {
             "fee_details": {
                 "amount": "0.00001"
             },
             "date": "7 Aug 2020, 08:33",
             "my_balance_change": "0",
             "tx_hash": "",
             "tx_hex": ""
         }
     })
    property var prepare_claim_rewards_result: General.clone(default_prepare_claim_rewards_result)

    // Override
    property var postClaim: () => {}

    // Local
    readonly property bool can_claim: current_ticker_infos.is_claimable && !API.get().wallet_pg.is_claiming_busy
    readonly property var claim_rpc_result: API.get().wallet_pg.claiming_rpc_data
    onClaim_rpc_resultChanged: {
        prepare_claim_rewards_result = General.clone(claim_rpc_result)
        if(!prepare_claim_rewards_result.withdraw_answer) {
            reset()
            return
        }

        console.log("Claim rewards result changed:", JSON.stringify(prepare_claim_rewards_result))

        let error = false
        if(prepare_claim_rewards_result.withdraw_answer.error) {
            toast.show(qsTr("Failed to prepare to claim rewards"), General.time_toast_important_error, prepare_claim_rewards_result.withdraw_answer.error)
            error = true
        }
        else if(prepare_claim_rewards_result.kmd_rewards_info.error) {
            toast.show(qsTr("Failed to get the rewards info"), General.time_toast_important_error, prepare_claim_rewards_result.kmd_rewards_info.error)
            error = true
        }

        if(error) root.close()
    }

    readonly property string send_result: API.get().wallet_pg.broadcast_rpc_data
    onSend_resultChanged: {
        if(send_result !== "") {
            stack_layout.currentIndex = 1
            postClaim()
        }
    }

    function prepareClaimRewards() {
        if(!can_claim) return

        stack_layout.currentIndex = 0
        reset()

        API.get().wallet_pg.claim_rewards()
    }

    function claimRewards() {
        API.get().wallet_pg.broadcast(prepare_claim_rewards_result.withdraw_answer.tx_hex)
    }

    function reset() {
        prepare_claim_rewards_result = General.clone(default_prepare_claim_rewards_result)
    }

    // Inside modal
    // width: stack_layout.children[stack_layout.currentIndex].width + horizontalPadding * 2
    width: 1200
    height: stack_layout.children[stack_layout.currentIndex].height + verticalPadding * 2
    StackLayout {
        width: parent.width
        id: stack_layout

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            ModalHeader {
                title: API.get().settings_pg.empty_string + (qsTr("Claim your %1 reward?", "TICKER").arg(API.get().wallet_pg.ticker))
            }

            DefaultBusyIndicator {
                visible: !can_claim || is_broadcast_busy
                Layout.alignment: Qt.AlignCenter
            }

            RowLayout {
                visible: can_claim

                Layout.fillWidth: true
                DefaultText {
                    Layout.fillWidth: true
                    color: can_confirm ? Style.colorText : Style.colorRed
                    text_value: API.get().settings_pg.empty_string + (
                                     !has_eligible_utxo ? ("❌ " + qsTr("No UTXOs eligible for claiming")) :
                                     !positive_claim_amount ? ("❌ " + qsTr("Transaction fee is higher than the reward!")) :

                                     qsTr("You will receive %1", "AMT TICKER").arg(General.formatCrypto("", prepare_claim_rewards_result.withdraw_answer.my_balance_change, API.get().wallet_pg.ticker)))
                }

                PrimaryButton {
                    text: API.get().settings_pg.empty_string + (qsTr("Refresh"))
                    onClicked: prepareClaimRewards()

                    enabled: can_claim
                }
            }

            DefaultText {
                text_value: API.get().settings_pg.empty_string + (General.cex_icon + ' <a href="https://support.komodoplatform.com/support/solutions/articles/29000024428-komodo-5-active-user-reward-all-you-need-to-know">' + qsTr('Read more about KMD active users rewards') + '</a>')
                wrapMode: Text.WordWrap
                font.pixelSize: Style.textSizeSmall2
            }

            // List header
            Item {
                visible: can_claim

                Layout.topMargin: 25
                Layout.fillWidth: true

                height: 40

                // Price
                DefaultText {
                    id: utxo_header
                    font.pixelSize: Style.textSizeSmall4

                    text_value: API.get().settings_pg.empty_string + (qsTr("UTXO"))

                    font.bold: true
                    horizontalAlignment: Text.AlignLeft

                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.000

                    anchors.verticalCenter: parent.verticalCenter
                }

                // Amount
                DefaultText {
                    id: amount_header

                    text_value: API.get().settings_pg.empty_string + (qsTr("Amount"))

                    font.pixelSize: utxo_header.font.pixelSize
                    font.bold: utxo_header.font.bold
                    horizontalAlignment: utxo_header.horizontalAlignment

                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.075

                    anchors.verticalCenter: parent.verticalCenter
                }

                // Reward
                DefaultText {
                    id: reward_header

                    text_value: API.get().settings_pg.empty_string + (qsTr("Reward"))

                    font.pixelSize: utxo_header.font.pixelSize
                    font.bold: utxo_header.font.bold
                    horizontalAlignment: Text.AlignLeft

                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.175

                    anchors.verticalCenter: parent.verticalCenter
                }

                // Accruing start
                DefaultText {
                    id: accruing_start_header

                    text_value: API.get().settings_pg.empty_string + (qsTr("Accruing Start"))

                    font.pixelSize: utxo_header.font.pixelSize
                    font.bold: utxo_header.font.bold
                    horizontalAlignment: Text.AlignLeft

                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.300

                    anchors.verticalCenter: parent.verticalCenter
                }

                // Accruing Stop
                DefaultText {
                    id: accruing_stop_header

                    text_value: API.get().settings_pg.empty_string + (qsTr("Accruing Stop"))

                    font.pixelSize: utxo_header.font.pixelSize
                    font.bold: utxo_header.font.bold
                    horizontalAlignment: Text.AlignLeft

                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.450

                    anchors.verticalCenter: parent.verticalCenter
                }

                // Time Left
                DefaultText {
                    id: time_left_header

                    text_value: API.get().settings_pg.empty_string + (qsTr("Time Left"))

                    font.pixelSize: utxo_header.font.pixelSize
                    font.bold: utxo_header.font.bold
                    horizontalAlignment: Text.AlignLeft

                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.600

                    anchors.verticalCenter: parent.verticalCenter
                }

                // Error
                DefaultText {
                    id: error_header

                    text_value: API.get().settings_pg.empty_string + (qsTr("Error"))

                    font.pixelSize: utxo_header.font.pixelSize
                    font.bold: utxo_header.font.bold
                    horizontalAlignment: Text.AlignLeft

                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.750

                    anchors.verticalCenter: parent.verticalCenter
                }

                // Line
                HorizontalLine {
                    width: parent.width
                    color: Style.colorWhite5
                    anchors.bottom: parent.bottom
                }
            }

            DefaultListView {
                visible: can_claim

                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumHeight: 500
                clip: true

                model: prepare_claim_rewards_result.kmd_rewards_info.result

                delegate: Item {
                    width: root.width
                    height: utxo_value.font.pixelSize * 1.5

                    // UTXO
                    DefaultText {
                        id: utxo_value

                        anchors.left: parent.left
                        anchors.leftMargin: utxo_header.anchors.leftMargin

                        font.pixelSize: utxo_header.font.pixelSize

                        text_value: API.get().settings_pg.empty_string + ("#" + (index + 1))
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Amount
                    DefaultText {
                        id: amount_value

                        anchors.left: parent.left
                        anchors.leftMargin: amount_header.anchors.leftMargin

                        font.pixelSize: utxo_value.font.pixelSize

                        text_value: API.get().settings_pg.empty_string + (modelData.amount)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Reward
                    DefaultText {
                        id: reward_value

                        anchors.left: parent.left
                        anchors.leftMargin: reward_header.anchors.leftMargin

                        font.pixelSize: utxo_value.font.pixelSize

                        text_value: API.get().settings_pg.empty_string + (modelData.accrued_rewards.Accrued || "-")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Accruing Start
                    DefaultText {
                        id: accruing_start_value

                        anchors.left: parent.left
                        anchors.leftMargin: accruing_start_header.anchors.leftMargin

                        font.pixelSize: utxo_value.font.pixelSize

                        text_value: API.get().settings_pg.empty_string + (modelData.accrue_start_at_human_date || "-")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Accruing Stop
                    DefaultText {
                        id: accruing_stop_value

                        anchors.left: parent.left
                        anchors.leftMargin: accruing_stop_header.anchors.leftMargin

                        font.pixelSize: utxo_value.font.pixelSize

                        text_value: API.get().settings_pg.empty_string + (modelData.accrue_stop_at_human_date || "-")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Time Left
                    DefaultText {
                        id: time_left_value

                        anchors.left: parent.left
                        anchors.leftMargin: time_left_header.anchors.leftMargin

                        font.pixelSize: utxo_value.font.pixelSize

                        text_value: API.get().settings_pg.empty_string + (modelData.accrue_stop_at ? General.secondsToTimeLeft(Date.now()/1000, modelData.accrue_stop_at) : '-')
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Error
                    DefaultText {
                        id: error_value

                        anchors.left: parent.left
                        anchors.leftMargin: error_header.anchors.leftMargin

                        font.pixelSize: utxo_value.font.pixelSize

                        text_value: {
                            let val = modelData.accrued_rewards.NotAccruedReason
                            if(val === null || val === undefined) return "-"

                            switch(val) {
                            case "LocktimeNotSet":
                                val = qsTr("Locktime is not set")
                                break
                            case "LocktimeLessThanThreshold":
                                val = qsTr("Locktime is less than the threshold")
                                break
                            case "UtxoHeightGreaterThanEndOfEra":
                                val = qsTr("UTXO height is greater than end of the era")
                                break
                            case "UtxoAmountLessThanTen":
                                val = qsTr("UTXO amount is less than 10")
                                break
                            case "OneHourNotPassedYet":
                                val = qsTr("One hour did not pass yet")
                                break
                            case "TransactionInMempool":
                                val = qsTr("Transaction is in mempool")
                                break
                            default:
                                val = qsTr("Unknown problem")
                                break
                            }

                            return API.get().settings_pg.empty_string + ("❌ " + val)
                        }

                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Line
                    HorizontalLine {
                        visible: prepare_claim_rewards_result.kmd_rewards_info.result &&
                                 index !== prepare_claim_rewards_result.kmd_rewards_info.result.length - 1
                        width: parent.width
                        color: Style.colorWhite9
                        anchors.bottom: parent.bottom
                    }
                }
            }

            // Buttons
            RowLayout {
                DefaultButton {
                    text: API.get().settings_pg.empty_string + (qsTr("Cancel"))
                    Layout.fillWidth: true
                    onClicked: root.close()
                }
                PrimaryButton {
                    text: API.get().settings_pg.empty_string + (qsTr("Confirm"))
                    Layout.fillWidth: true
                    onClicked: claimRewards()
                    enabled: can_confirm
                }
            }
        }

        // Result Page
        SendResult {
            result: ({
                balance_change: prepare_claim_rewards_result.withdraw_answer.my_balance_change,
                fees: prepare_claim_rewards_result.withdraw_answer.fee_details.amount,
                date: prepare_claim_rewards_result.withdraw_answer.date
            })
            tx_hash: send_result

            function onClose() { root.close() }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:600;width:1200}
}
##^##*/
