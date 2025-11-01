// Copyright (c) 2011-2020 The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef BITCOINPURPLE_QT_BITCOINPURPLEADDRESSVALIDATOR_H
#define BITCOINPURPLE_QT_BITCOINPURPLEADDRESSVALIDATOR_H

#include <QValidator>

/** Base58 entry widget validator, checks for valid characters and
 * removes some whitespace.
 */
class BitcoinPurpleAddressEntryValidator : public QValidator
{
    Q_OBJECT

public:
    explicit BitcoinPurpleAddressEntryValidator(QObject *parent);

    State validate(QString &input, int &pos) const override;
};

/** BitcoinPurple address widget validator, checks for a valid bitcoinpurple address.
 */
class BitcoinPurpleAddressCheckValidator : public QValidator
{
    Q_OBJECT

public:
    explicit BitcoinPurpleAddressCheckValidator(QObject *parent);

    State validate(QString &input, int &pos) const override;
};

#endif // BITCOINPURPLE_QT_BITCOINPURPLEADDRESSVALIDATOR_H
