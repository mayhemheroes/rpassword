use std::env;
use std::fs;
use std::io::Cursor;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
        // File as input
        let filename = &args[1];
        let contents = fs::read_to_string(filename)
            .expect("Something went wrong reading the file");
        let mut mock_input = Cursor::new(contents.as_bytes().to_owned());
        let password = rpassword::read_password_from_bufread(&mut mock_input).unwrap();
    }
    else {
        // Use stdin as input
        let pass = rpassword::read_password().unwrap();
    }
}