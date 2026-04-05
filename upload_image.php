<?php
header('Content-Type: application/json');

$target_dir = "uploads/";

// Create directory if not exists
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['image'])) {
    $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
    $new_filename = uniqid() . '.' . $file_extension;
    $target_file = $target_dir . $new_filename;

    // Optional: Validate if it's an actual image
    $check = getimagesize($_FILES["image"]["tmp_name"]);
    if($check !== false) {
        if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
            $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https" : "http";
            $domain = $_SERVER['HTTP_HOST'];
            $imageurl = $protocol . "://" . $domain . "/uploads/" . $new_filename;
            
            echo json_encode(['status' => 'success', 'url' => $imageurl]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'File could not be moved.']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'File is not an image.']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request. Use POST and provide an "image" field.']);
}
?>
