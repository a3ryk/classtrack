class UniversityItem {
  final String id;
  final String name;
  final String state;
  final String city;
  final String type; // Central, State, IIT/NIT, Deemed, Private
  final bool hasAffiliatedColleges;

  const UniversityItem({
    required this.id,
    required this.name,
    required this.state,
    required this.city,
    required this.type,
    this.hasAffiliatedColleges = true,
  });
}

class IndianUniversitiesData {
  static const List<String> statesAndUTs = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh (UT)',
    'Chhattisgarh',
    'Delhi (NCT)',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu & Kashmir (UT)',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry (UT)',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  static const List<UniversityItem> universities = [
    // --- ASSAM ---
    UniversityItem(id: 'gu_gauhati', name: 'Gauhati University (GU)', state: 'Assam', city: 'Guwahati', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'du_dibrugarh', name: 'Dibrugarh University (DU)', state: 'Assam', city: 'Dibrugarh', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'au_assam_univ', name: 'Assam University', state: 'Assam', city: 'Silchar & Diphu', type: 'Central University', hasAffiliatedColleges: true),
    UniversityItem(id: 'iit_guwahati', name: 'Indian Institute of Technology Guwahati (IITG)', state: 'Assam', city: 'Guwahati', type: 'IIT / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'tezpur_univ', name: 'Tezpur University', state: 'Assam', city: 'Tezpur', type: 'Central University', hasAffiliatedColleges: false),
    UniversityItem(id: 'cotton_univ', name: 'Cotton University (CU)', state: 'Assam', city: 'Guwahati', type: 'State University', hasAffiliatedColleges: false),
    UniversityItem(id: 'aau_jorhat', name: 'Assam Agricultural University (AAU)', state: 'Assam', city: 'Jorhat', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'astu_guwahati', name: 'Assam Science and Technology University (ASTU)', state: 'Assam', city: 'Guwahati', type: 'State Technical Univ', hasAffiliatedColleges: true),
    UniversityItem(id: 'ssuhs_health', name: 'Srimanta Sankaradeva University of Health Sciences (SSUHS)', state: 'Assam', city: 'Guwahati', type: 'State Medical Univ', hasAffiliatedColleges: true),
    UniversityItem(id: 'bodoland_univ', name: 'Bodoland University (BU)', state: 'Assam', city: 'Kokrajhar', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'bhattadev_univ', name: 'Bhattadev University', state: 'Assam', city: 'Bajali', type: 'State University', hasAffiliatedColleges: false),
    UniversityItem(id: 'madhabdev_univ', name: 'Madhabdev University', state: 'Assam', city: 'Narayanpur', type: 'State University', hasAffiliatedColleges: false),
    UniversityItem(id: 'rtu_hojai', name: 'Rabindranath Tagore University (RTU)', state: 'Assam', city: 'Hojai', type: 'State University', hasAffiliatedColleges: false),
    UniversityItem(id: 'kbvs_nalbari', name: 'Kumar Bhaskar Varma Sanskrit & Ancient Studies Univ', state: 'Assam', city: 'Nalbari', type: 'State University', hasAffiliatedColleges: false),
    UniversityItem(id: 'majuli_culture', name: 'Majuli University of Culture', state: 'Assam', city: 'Majuli', type: 'State University', hasAffiliatedColleges: false),
    UniversityItem(id: 'nluja_assam', name: 'National Law University and Judicial Academy (NLUJA)', state: 'Assam', city: 'Guwahati', type: 'National Law Univ', hasAffiliatedColleges: false),
    UniversityItem(id: 'iiit_guwahati', name: 'Indian Institute of Information Technology Guwahati (IIITG)', state: 'Assam', city: 'Guwahati', type: 'IIIT / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'royal_global', name: 'The Royal Global University (RGU)', state: 'Assam', city: 'Guwahati', type: 'Private University', hasAffiliatedColleges: false),
    UniversityItem(id: 'don_bosco', name: 'Assam Don Bosco University (ADBU)', state: 'Assam', city: 'Guwahati', type: 'Private University', hasAffiliatedColleges: false),
    UniversityItem(id: 'kaziranga_univ', name: 'Kaziranga University (KU)', state: 'Assam', city: 'Jorhat', type: 'Private University', hasAffiliatedColleges: false),
    UniversityItem(id: 'downtown_univ', name: 'Assam Down Town University (ADTU)', state: 'Assam', city: 'Guwahati', type: 'Private University', hasAffiliatedColleges: false),
    UniversityItem(id: 'mssv_nagaon', name: 'Mahapurusha Srimanta Sankaradeva Viswavidyalaya (MSSV)', state: 'Assam', city: 'Nagaon', type: 'Private University', hasAffiliatedColleges: false),

    // --- DELHI ---
    UniversityItem(id: 'du_delhi', name: 'University of Delhi (DU)', state: 'Delhi (NCT)', city: 'New Delhi', type: 'Central University', hasAffiliatedColleges: true),
    UniversityItem(id: 'jnu_delhi', name: 'Jawaharlal Nehru University (JNU)', state: 'Delhi (NCT)', city: 'New Delhi', type: 'Central University', hasAffiliatedColleges: false),
    UniversityItem(id: 'jmi_delhi', name: 'Jamia Millia Islamia (JMI)', state: 'Delhi (NCT)', city: 'New Delhi', type: 'Central University', hasAffiliatedColleges: false),
    UniversityItem(id: 'iit_delhi', name: 'Indian Institute of Technology Delhi (IITD)', state: 'Delhi (NCT)', city: 'New Delhi', type: 'IIT / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'dtu_delhi', name: 'Delhi Technological University (DTU)', state: 'Delhi (NCT)', city: 'New Delhi', type: 'State University', hasAffiliatedColleges: false),
    UniversityItem(id: 'ipu_delhi', name: 'Guru Gobind Singh Indraprastha University (GGSIPU)', state: 'Delhi (NCT)', city: 'New Delhi', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'nsut_delhi', name: 'Netaji Subhas University of Technology (NSUT)', state: 'Delhi (NCT)', city: 'New Delhi', type: 'State University', hasAffiliatedColleges: false),

    // --- KARNATAKA ---
    UniversityItem(id: 'vtu_karnataka', name: 'Visvesvaraya Technological University (VTU)', state: 'Karnataka', city: 'Belagavi', type: 'State Technical Univ', hasAffiliatedColleges: true),
    UniversityItem(id: 'iisc_bangalore', name: 'Indian Institute of Science (IISc)', state: 'Karnataka', city: 'Bengaluru', type: 'Deemed / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'bangalore_univ', name: 'Bangalore University', state: 'Karnataka', city: 'Bengaluru', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'manipal_mahe', name: 'Manipal Academy of Higher Education (MAHE)', state: 'Karnataka', city: 'Manipal', type: 'Deemed University', hasAffiliatedColleges: false),
    UniversityItem(id: 'nitk_surathkal', name: 'National Institute of Technology Karnataka (NITK)', state: 'Karnataka', city: 'Surathkal', type: 'NIT / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'mysore_univ', name: 'University of Mysore', state: 'Karnataka', city: 'Mysuru', type: 'State University', hasAffiliatedColleges: true),

    // --- MAHARASHTRA ---
    UniversityItem(id: 'mumbai_univ', name: 'University of Mumbai', state: 'Maharashtra', city: 'Mumbai', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'sppu_pune', name: 'Savitribai Phule Pune University (SPPU)', state: 'Maharashtra', city: 'Pune', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'iit_bombay', name: 'Indian Institute of Technology Bombay (IITB)', state: 'Maharashtra', city: 'Mumbai', type: 'IIT / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'ict_mumbai', name: 'Institute of Chemical Technology (ICT)', state: 'Maharashtra', city: 'Mumbai', type: 'Deemed University', hasAffiliatedColleges: false),
    UniversityItem(id: 'vnit_nagpur', name: 'Visvesvaraya National Institute of Technology (VNIT)', state: 'Maharashtra', city: 'Nagpur', type: 'NIT / Nat\'l Importance', hasAffiliatedColleges: false),

    // --- UTTAR PRADESH ---
    UniversityItem(id: 'bhu_varanasi', name: 'Banaras Hindu University (BHU)', state: 'Uttar Pradesh', city: 'Varanasi', type: 'Central University', hasAffiliatedColleges: true),
    UniversityItem(id: 'amu_aligarh', name: 'Aligarh Muslim University (AMU)', state: 'Uttar Pradesh', city: 'Aligarh', type: 'Central University', hasAffiliatedColleges: true),
    UniversityItem(id: 'iit_kanpur', name: 'Indian Institute of Technology Kanpur (IITK)', state: 'Uttar Pradesh', city: 'Kanpur', type: 'IIT / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'aktu_lucknow', name: 'Dr. A.P.J. Abdul Kalam Technical University (AKTU)', state: 'Uttar Pradesh', city: 'Lucknow', type: 'State Technical Univ', hasAffiliatedColleges: true),
    UniversityItem(id: 'allahabad_univ', name: 'University of Allahabad', state: 'Uttar Pradesh', city: 'Prayagraj', type: 'Central University', hasAffiliatedColleges: true),

    // --- TAMIL NADU ---
    UniversityItem(id: 'anna_univ', name: 'Anna University', state: 'Tamil Nadu', city: 'Chennai', type: 'State Technical Univ', hasAffiliatedColleges: true),
    UniversityItem(id: 'madras_univ', name: 'University of Madras', state: 'Tamil Nadu', city: 'Chennai', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'iit_madras', name: 'Indian Institute of Technology Madras (IITM)', state: 'Tamil Nadu', city: 'Chennai', type: 'IIT / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'nit_trichy', name: 'National Institute of Technology Tiruchirappalli (NIT Trichy)', state: 'Tamil Nadu', city: 'Tiruchirappalli', type: 'NIT / Nat\'l Importance', hasAffiliatedColleges: false),
    UniversityItem(id: 'srm_chennai', name: 'SRM Institute of Science and Technology', state: 'Tamil Nadu', city: 'Chennai', type: 'Deemed University', hasAffiliatedColleges: false),
    UniversityItem(id: 'vit_vellore', name: 'Vellore Institute of Technology (VIT)', state: 'Tamil Nadu', city: 'Vellore', type: 'Deemed University', hasAffiliatedColleges: false),

    // --- WEST BENGAL ---
    UniversityItem(id: 'calcutta_univ', name: 'University of Calcutta', state: 'West Bengal', city: 'Kolkata', type: 'State University', hasAffiliatedColleges: true),
    UniversityItem(id: 'jadavpur_univ', name: 'Jadavpur University', state: 'West Bengal', city: 'Kolkata', type: 'State University', hasAffiliatedColleges: false),
    UniversityItem(id: 'visva_bharati', name: 'Visva-Bharati University', state: 'West Bengal', city: 'Santiniketan', type: 'Central University', hasAffiliatedColleges: false),
    UniversityItem(id: 'iit_kharagpur', name: 'Indian Institute of Technology Kharagpur (IITKGP)', state: 'West Bengal', city: 'Kharagpur', type: 'IIT / Nat\'l Importance', hasAffiliatedColleges: false),
  ];
}
