import cv2
import numpy as np
from PIL import Image
from io import BytesIO
from typing import List, Tuple
from app.models.cube import DetectionResponse, FaceName, FaceColor


class DetectionService:
    """Service for detecting Rubik's cube colors from images."""
    
    def __init__(self):
        # Define color ranges in HSV (optimized for Rubik's cube colors)
        self.color_ranges = {
            FaceColor.WHITE: {
                'lower': np.array([0, 0, 200]),
                'upper': np.array([180, 30, 255]),
            },
            FaceColor.YELLOW: {
                'lower': np.array([20, 100, 100]),
                'upper': np.array([35, 255, 255]),
            },
            FaceColor.RED: {
                'lower1': np.array([0, 100, 100]),
                'upper1': np.array([10, 255, 255]),
                'lower2': np.array([170, 100, 100]),
                'upper2': np.array([180, 255, 255]),
            },
            FaceColor.ORANGE: {
                'lower': np.array([10, 100, 100]),
                'upper': np.array([20, 255, 255]),
            },
            FaceColor.BLUE: {
                'lower': np.array([100, 100, 100]),
                'upper': np.array([130, 255, 255]),
            },
            FaceColor.GREEN: {
                'lower': np.array([40, 50, 50]),
                'upper': np.array([80, 255, 255]),
            },
        }
    
    async def detect_face(self, image_bytes: bytes, face_name: str) -> DetectionResponse:
        """
        Detect colors of a Rubik's cube face from image.
        
        Args:
            image_bytes: Image data as bytes
            face_name: Name of the face being detected
        
        Returns:
            DetectionResponse with detected colors
        """
        try:
            # Convert bytes to image
            image = Image.open(BytesIO(image_bytes))
            img_array = np.array(image)
            
            # Convert RGB to BGR for OpenCV
            if len(img_array.shape) == 3 and img_array.shape[2] == 3:
                img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
            
            # Preprocess image
            processed_img = self._preprocess_image(img_array)
            
            # Detect grid and extract stickers
            stickers = self._detect_grid(processed_img)
            
            if stickers is None or len(stickers) != 9:
                # Fallback: try simpler grid division
                stickers = self._simple_grid_division(processed_img)
            
            # Classify colors for each sticker
            colors = self._classify_stickers(stickers, processed_img)
            
            # Calculate confidence based on detection quality
            confidence = self._calculate_confidence(stickers, colors)
            
            return DetectionResponse(
                success=True,
                face_name=FaceName(face_name),
                colors=colors,
                confidence=confidence,
                message="Colors detected successfully"
            )
        
        except Exception as e:
            return DetectionResponse(
                success=False,
                face_name=FaceName(face_name),
                colors=[],
                confidence=0.0,
                message=f"Detection failed: {str(e)}"
            )
    
    def _preprocess_image(self, image: np.ndarray) -> np.ndarray:
        """
        Preprocess image for better detection.
        """
        # Resize if too large
        height, width = image.shape[:2]
        max_size = 800
        if max(height, width) > max_size:
            scale = max_size / max(height, width)
            image = cv2.resize(image, None, fx=scale, fy=scale)
        
        # Apply bilateral filter to reduce noise while keeping edges sharp
        image = cv2.bilateralFilter(image, 9, 75, 75)
        
        # Enhance contrast
        lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        l = clahe.apply(l)
        enhanced = cv2.merge([l, a, b])
        image = cv2.cvtColor(enhanced, cv2.COLOR_LAB2BGR)
        
        return image
    
    def _detect_grid(self, image: np.ndarray) -> List[Tuple[int, int, int, int]]:
        """
        Detect 3x3 grid of stickers using contour detection.
        Returns list of 9 bounding boxes [(x, y, w, h), ...]
        """
        try:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Apply adaptive thresholding
            thresh = cv2.adaptiveThreshold(
                gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv2.THRESH_BINARY, 11, 2
            )
            
            # Find contours
            contours, _ = cv2.findContours(
                thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE
            )
            
            # Filter contours by area and aspect ratio
            sticker_contours = []
            height, width = image.shape[:2]
            min_area = (height * width) * 0.01  # At least 1% of image
            max_area = (height * width) * 0.15  # At most 15% of image
            
            for contour in contours:
                area = cv2.contourArea(contour)
                if min_area < area < max_area:
                    x, y, w, h = cv2.boundingRect(contour)
                    aspect_ratio = float(w) / h if h > 0 else 0
                    
                    # Stickers should be roughly square
                    if 0.7 < aspect_ratio < 1.3:
                        sticker_contours.append((x, y, w, h, area))
            
            # Sort contours by position (top to bottom, left to right)
            if len(sticker_contours) >= 9:
                sticker_contours.sort(key=lambda b: (b[1] // 50, b[0]))  # Group by rows
                return [(x, y, w, h) for x, y, w, h, _ in sticker_contours[:9]]
            
            return None
        
        except Exception:
            return None
    
    def _simple_grid_division(self, image: np.ndarray) -> List[Tuple[int, int, int, int]]:
        """
        Simple fallback: divide image into 3x3 grid.
        """
        height, width = image.shape[:2]
        
        # Assume the cube face is centered, use middle 80% of image
        margin_h = int(height * 0.1)
        margin_w = int(width * 0.1)
        
        grid_height = (height - 2 * margin_h) // 3
        grid_width = (width - 2 * margin_w) // 3
        
        stickers = []
        for row in range(3):
            for col in range(3):
                x = margin_w + col * grid_width
                y = margin_h + row * grid_height
                stickers.append((x, y, grid_width, grid_height))
        
        return stickers
    
    def _classify_stickers(
        self,
        stickers: List[Tuple[int, int, int, int]],
        image: np.ndarray
    ) -> List[List[FaceColor]]:
        """
        Classify the color of each sticker.
        Returns 3x3 grid of colors.
        """
        colors = []
        hsv_image = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        
        for i in range(9):
            x, y, w, h = stickers[i]
            
            # Extract center region of sticker (avoid edges)
            center_margin = 0.2
            cx = x + int(w * center_margin)
            cy = y + int(h * center_margin)
            cw = int(w * (1 - 2 * center_margin))
            ch = int(h * (1 - 2 * center_margin))
            
            # Extract ROI
            roi = hsv_image[cy:cy+ch, cx:cx+cw]
            
            if roi.size == 0:
                colors.append(FaceColor.WHITE)  # Default
                continue
            
            # Classify color
            detected_color = self._classify_color(roi)
            colors.append(detected_color)
        
        # Reshape to 3x3
        return [colors[i:i+3] for i in range(0, 9, 3)]
    
    def _classify_color(self, roi: np.ndarray) -> FaceColor:
        """
        Classify the color of a single sticker region.
        """
        # Get median color (more robust than mean)
        median_color = np.median(roi.reshape(-1, 3), axis=0)
        
        # Calculate distance to each color
        min_distance = float('inf')
        detected_color = FaceColor.WHITE
        
        for color, ranges in self.color_ranges.items():
            if color == FaceColor.RED:
                # Red wraps around in HSV, check both ranges
                mask1 = cv2.inRange(roi, ranges['lower1'], ranges['upper1'])
                mask2 = cv2.inRange(roi, ranges['lower2'], ranges['upper2'])
                pixels = cv2.countNonZero(mask1) + cv2.countNonZero(mask2)
            else:
                mask = cv2.inRange(roi, ranges['lower'], ranges['upper'])
                pixels = cv2.countNonZero(mask)
            
            # Calculate percentage of matching pixels
            total_pixels = roi.shape[0] * roi.shape[1]
            match_percentage = pixels / total_pixels if total_pixels > 0 else 0
            
            # Use inverse of percentage as "distance"
            distance = 1 - match_percentage
            
            if distance < min_distance:
                min_distance = distance
                detected_color = color
        
        return detected_color
    
    def _calculate_confidence(
        self,
        stickers: List[Tuple[int, int, int, int]],
        colors: List[List[FaceColor]]
    ) -> float:
        """
        Calculate confidence score based on detection quality.
        """
        # Base confidence
        confidence = 0.7
        
        # Boost if we detected exactly 9 stickers
        if len(stickers) == 9:
            confidence += 0.1
        
        # Check color distribution (should have dominant center color)
        flat_colors = [c for row in colors for c in row]
        center_color = colors[1][1]  # Center sticker
        same_as_center = sum(1 for c in flat_colors if c == center_color)
        
        # Ideally should have 9 of same color on a face
        if same_as_center >= 7:
            confidence += 0.1
        elif same_as_center >= 5:
            confidence += 0.05
        
        return min(confidence, 0.95)  # Cap at 0.95
