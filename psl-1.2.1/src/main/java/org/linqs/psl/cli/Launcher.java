package org.linqs.psl.cli;

/**
 * A shim to make compatible with the official psl-cli.
 */
public class Launcher {
   public static void main(String[] args) {
      org.linqs.psl.nips17.psl121.Launcher.main(args);
   }
}
