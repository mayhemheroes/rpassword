#![no_main]

//! Ported from the fork's old harness `fuzzing/src/fuzz_password_input.rs`, which read a
//! file's bytes as a password via `rpassword::read_password_from_bufread`. We keep that path
//! and ALSO drive the modern `read_password_with_config(ConfigBuilder::input_reader(...))`,
//! which runs rpassword's full input state machine (lib.rs: control chars, CSI/SS3 escape
//! sequences, backspace/Ctrl-U/Ctrl-W editing, feedback) so the fuzzer reaches many more edges
//! than the deprecated one-line reader alone.

use libfuzzer_sys::fuzz_target;
use rpassword::{read_password_with_config, ConfigBuilder};
use std::io::Cursor;

fuzz_target!(|data: &[u8]| {
    // Modern path: feed the bytes through the real password-reading state machine.
    // output_discard() keeps it self-contained (no TTY / no file writes).
    let config = ConfigBuilder::new()
        .input_reader(Cursor::new(data.to_vec()))
        .output_discard()
        .password_feedback_mask('*')
        .build();
    let _ = read_password_with_config(config);

    // Legacy path the original fork harness exercised (still public, deprecated).
    #[allow(deprecated)]
    {
        let mut reader = Cursor::new(data.to_vec());
        let _ = rpassword::read_password_from_bufread(&mut reader);
    }
});
