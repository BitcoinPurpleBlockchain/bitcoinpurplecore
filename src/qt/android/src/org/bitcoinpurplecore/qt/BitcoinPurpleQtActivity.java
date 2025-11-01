package org.bitcoinpurplecore.qt;

import android.os.Bundle;
import android.system.ErrnoException;
import android.system.Os;

import org.qtproject.qt5.android.bindings.QtActivity;

import java.io.File;

public class BitcoinPurpleQtActivity extends QtActivity
{
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        final File bitcoinpurpleDir = new File(getFilesDir().getAbsolutePath() + "/.bitcoinpurple");
        if (!bitcoinpurpleDir.exists()) {
            bitcoinpurpleDir.mkdir();
        }

        super.onCreate(savedInstanceState);
    }
}
