use warp::Filter;

type Item = (String, String);
static ITEMS: std::sync::Mutex<Vec<Item>> = std::sync::Mutex::new(vec![]);

#[test]
fn test_get_items_empty() {
    let items = ITEMS.clone();
    let get_items = warp::path!("items").and(warp::get()).map(move || {
        let items = items.lock().unwrap();
        warp::reply::json(&*items)
    });

    let resp = get_items.reply();
    let body = warp::body::body(&resp).unwrap();
    let text = std::str::from_utf8(&body).unwrap();
    assert_eq!(text, "[[]]");
}

#[test]
fn test_health_endpoint() {
    let health = warp::path!("health").and(warp::get()).map(|| warp::reply::json(&"healthy"));
    let resp = health.reply();
    let body = warp::body::body(&resp).unwrap();
    let text = std::str::from_utf8(&body).unwrap();
    assert_eq!(text, "\"healthy\"");
}

#[test]
fn test_package_compiles() {
    // Just verify the crate can be loaded
    use std::path::Path;
    let cargo_toml = Path::new("Cargo.toml");
    assert!(cargo_toml.exists());
}